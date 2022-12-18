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

const login = cpf => {
    return new Promise((resolve, reject) => {
        return serviceUserCredential.getByCpf('cartos', cpf)
            .then(serviceUserCredential => {
                if (!serviceUserCredential) throw new Error(`Nenhum usuário encontrado com o cpf ${cpf}`);

                return cartosHttpRequest.login(
                    serviceUserCredential.cpf,
                    serviceUserCredential.password
                );
            })

            .then(loginResult => {
                return resolve(loginResult);
            })

            .catch(e => {
                return reject(e);
            })
    })
}

const changeAccount = (cpf, accountId, currentCredentials) => {
    return new Promise((resolve, reject) => {

        // Já foi verificado, mas, se a conta for a mesma do token atual, retorna as mesmas credenciais
        if (currentCredentials && currentCredentials.accountId === accountId) {
            return resolve(currentCredentials);
        }

        // Verifica se a conta existe
        collectionCartosAccounts.getDoc(accountId)
            .then(_ => {

                // Se já existe credenciais (de login ou de outra conta), apenas troca de conta;
                if (currentCredentials) {
                    return cartosHttpRequest.changeAccount(accountId, currentCredentials.token)

                        .then(loginResult => {
                            return resolve(loginResult);
                        })

                        .catch(e => {
                            return reject(e);
                        })
                }

                // Não existem credenciais ou elas são inválidas. Faz o login e muda de conta.
                return login(cpf)

                    .then(loginResult => {
                        return cartosHttpRequest.changeAccount(accountId, loginResult.token);
                    })

                    .then(loginResult => {
                        return resolve(loginResult);
                    })

                    .catch(e => {
                        return reject(e);
                    })
            })

            .catch(e => {
                return reject(e);
            })
    })
}

const getCredential = (cpf, accountId) => {
    return new Promise((resolve, reject) => {

        let result = {
            success: false
        };

        const
            path = getPathAccountToken(cpf),
            nowMilliseconds = global.nowMilliseconds();

        if (typeof accountId === 'undefined') accountId = 'login';

        // Verifica se o token já existe no Buffer (RealTimeDatabase)
        return admin.database().ref(path).once("value")
            .then(refAccountTokenResult => {
                refAccountTokenResult = refAccountTokenResult.val() || null;

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

                    return null
                }

                // Em vez disso, experimente usar o opaqueRefreshTokenId
                refAccountTokenResult = null;

                // Se o tipo de conta for login
                if (accountId === 'login' || accountId === 'any') {
                    return login(cpf);
                } else {
                    return changeAccount(cpf, accountId);
                }

            })

            .then(accountResult => {
                if (result.success) return;

                accountResult.accountId = accountId;
                accountResult.expire = global.nowMilliseconds(10, 'minutes');

                result = { ...accountResult };
                result.success = true;
                result.source = 'cartos';

                return admin.database().ref(path).set(accountResult);
            })

            .then(_ => {
                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
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
