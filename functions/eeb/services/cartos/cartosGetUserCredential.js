"use strict";

const admin = require("firebase-admin");

const Joi = require('joi');
const global = require('../../../global');
const eebService = require('../../eventBusService').abstract;

const serviceUserCredential = require('../../../business/serviceUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosAccounts = firestoreDAL.cartosAccounts();

const tokenExpireMinutes = 10;
const showInfo = false;

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().default('login').optional()
    });

    return schema;
}

const getPathAccountToken = cpf => {
    return `/tokens/${cpf}/cartos/currentToken`;
}

async function login(cpf) {
    if (showInfo) console.info(`login ${cpf}`);

    const userCredential = await serviceUserCredential.getByCpf('cartos', cpf);

    if (!userCredential) throw new Error(`Nenhum usuário encontrado com o cpf ${cpf}`);

    const loginResult = await cartosHttpRequest.login(
        userCredential.cpf,
        userCredential.password
    );

    if (showInfo) console.info(`login success. Token ${loginResult.token}`);

    return loginResult;
}

async function changeAccount(cpf, accountId, currentCredentials) {
    if (showInfo) console.info(`changeAccount. CPF ${cpf}, accountId ${accountId}`);

    const expire = global.nowMilliseconds(tokenExpireMinutes, 'minutes');

    if (
        currentCredentials &&
        currentCredentials.accountId === accountId &&
        currentCredentials.expire > expire
    ) {
        if (showInfo) console.info(`Same credentials, not expired...`);

        return currentCredentials;
    }

    // Verifica se o accountId pertence ao CPF
    const cartosAccount = await collectionCartosAccounts.getDoc(accountId, true);

    if (cartosAccount.cpf !== cpf) throw new Error(`A conta não pertence ao cpf ${cpf}`);

    if (currentCredentials) {
        try {
            if (showInfo) console.info(`Changing account...`);
            const result = await cartosHttpRequest.changeAccount(accountId, currentCredentials.token);
            if (showInfo) console.info(`Change account success...`);

            return result;
        }
        catch (e) {
            if (showInfo) console.info(`Change account error. Refreshing token...`);
            const refreshCredentials = await refreshToken(cpf, currentCredentials.token, currentCredentials.opaqueRefreshTokenId);
            if (showInfo) console.info(`Changing account...`);

            return await cartosHttpRequest.changeAccount(accountId, refreshCredentials.token);
        }
    }

    const loginResult = await login(cpf);
    return await cartosHttpRequest.changeAccount(accountId, loginResult.token);
}

/* O refresh pode ser feito com um token antigo, passando-se o opaqueRefreshTokenId */
async function refreshToken(cpf, token, opaqueRefreshTokenId) {
    if (showInfo) console.info(`refreshToken ${cpf}`);

    const path = getPathAccountToken(cpf);

    try {
        if (showInfo) console.info(`refreshToken Call...`);
        const refreshTokenResult = await cartosHttpRequest.refreshToken(token, opaqueRefreshTokenId);
        if (showInfo) console.info(`refreshToken Success...`);

        refreshTokenResult.expire = global.nowMilliseconds(10, 'minutes');

        await admin.database().ref(path).set(refreshTokenResult);

        return refreshTokenResult;
    }
    catch (e) {
        // Erro na tentativa de refresh... refaz o login
        if (showInfo) console.info(`refreshToken erro. Login...`);

        return await login(cpf);
    }

}

async function getCredential(cpf, accountId) {

    let result = {
        success: false
    };

    const
        path = getPathAccountToken(cpf),
        nowMilliseconds = global.nowMilliseconds();

    if (typeof accountId === 'undefined') accountId = 'login';

    const refAccountTokenResult = (await admin.database().ref(path).once("value")).val();

    // Se existe um token não expirado ativo na mesma conta
    if (
        refAccountTokenResult && // A autenticação existe no cache
        (accountId === 'any' || refAccountTokenResult.accountId === accountId) && // Token da mesma conta
        refAccountTokenResult.token && // Existe um token no cache
        refAccountTokenResult.expire && // Existe data de expiração
        nowMilliseconds < refAccountTokenResult.expire // O token não expirou
    ) {
        result = refAccountTokenResult;

        result.source = 'buffer';
        result.success = true;

        return result
    }

    // Tentativa de Refresh do Token Antigo
    if (
        refAccountTokenResult && // A autenticação existe no cache
        refAccountTokenResult.token && // Existe token
        refAccountTokenResult.opaqueRefreshTokenId && // Existe o token de renovação
        refAccountTokenResult.accountId === accountId && // O token é da mesma conta
        refAccountTokenResult.expire && // Existe data de expiração
        nowMilliseconds > refAccountTokenResult.expire // O token está expirado
    ) {
        result = await refreshToken(cpf, refAccountTokenResult.token, refAccountTokenResult.opaqueRefreshTokenId);

        if (result) {
            result.success = true;
            result.source = 'refresh';

            return result;
        }
    }

    const accountResult = accountId === 'login' || accountId === 'any' ?
        await login(cpf) :
        await changeAccount(cpf, accountId, refAccountTokenResult);

    accountResult.accountId = accountId;
    accountResult.expire = global.nowMilliseconds(10, 'minutes');

    result = { ...accountResult };
    result.success = true;
    result.source = 'cartos';

    await admin.database().ref(path).set(accountResult);

    return result;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: false
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return getCredential(result.parm.cpf, result.parm.accountId || 'login');
                })

                .then(getCredentialResult => {
                    return resolve(getCredentialResult);
                })

                .catch(e => {
                    console.error('run', JSON.stringify(e));
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    if (!data.cpf) throw new Error('o CPF é obrigatório...');

    const service = new Service(request, response, {
        name: 'get-user-credential',
        async: false, // Este evento nunca é assincrono
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;
exports.getCredential = getCredential;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
