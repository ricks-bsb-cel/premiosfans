"use strict";

const admin = require("firebase-admin");

const path = require('path');
const Joi = require('joi');
const global = require('../../../global');
const eebService = require('../../eventBusService').abstract;

const serviceUserCredential = require('../../../business/serviceUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosAccounts = firestoreDAL.cartosAccounts();

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
    const userCredential = await serviceUserCredential.getByCpf('cartos', cpf);

    if (!userCredential) throw new Error(`Nenhum usuário encontrado com o cpf ${cpf}`);

    const loginResult = await cartosHttpRequest.login(
        userCredential.cpf,
        userCredential.password
    );

    return loginResult;
}

async function changeAccount(cpf, accountId, currentCredentials) {
    if (currentCredentials && currentCredentials.accountId === accountId) {
        // Já foi verificado, mas, se a conta for a mesma do token atual, retorna as mesmas credenciais
        return currentCredentials;
    }

    const cartosAccount = await collectionCartosAccounts.getDoc(accountId, true);

    if (cartosAccount.cpf !== cpf) {
        throw new Error(`A conta não pertence ao cpf ${cpf}`);
    }

    if (currentCredentials) {
        return await cartosHttpRequest.changeAccount(accountId, currentCredentials.token);
    }

    const loginResult = await login(cpf);
    const changeAccount = await cartosHttpRequest.changeAccount(accountId, loginResult.token);

    return changeAccount;
}

async function getCredential(cpf, accountId) {

    let result = {
        success: false
    };

    const
        path = getPathAccountToken(cpf),
        nowMilliseconds = global.nowMilliseconds();

    if (typeof accountId === 'undefined') accountId = 'login';

    let refAccountTokenResult = (await admin.database().ref(path).once("value")).val();

    if (
        refAccountTokenResult &&
        (accountId === 'any' || refAccountTokenResult.accountId === accountId) &&
        refAccountTokenResult.token && // Existe um token no cache
        refAccountTokenResult.expire && // Existe data de expiração
        nowMilliseconds < refAccountTokenResult.expire // O token é da mesma conta
    ) {
        result = refAccountTokenResult;

        result.source = 'buffer';
        result.success = true;

        return result
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
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let result = {
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
