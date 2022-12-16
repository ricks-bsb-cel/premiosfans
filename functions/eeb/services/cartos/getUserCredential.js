"use strict";

const admin = require("firebase-admin");

const path = require('path');
const Joi = require('joi');
const global = require('../../../global');
const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;

const serviceUserCredential = require('../../../business/serviceUserCredential');
const { head } = require("lodash");
const resultPassword = true;

const schema = _ => {
    const schema = Joi.object({
        tipo: Joi.string().default('cartos').optional(),
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().default('login').optional()
    });

    return schema;
}

const getPathAccountToken = (cpf, accountId) => {
    return `/tokens/${cpf}/cartos/${accountId}`;
}

const login = (cpf, password) => {
    return new Promise((resolve, reject) => {

        let result, cartosConfig;

        return secretManager.get('cartos-api-config')
            .then(secretManagerResult => {
                cartosConfig = secretManagerResult;

                const endPoint = `${cartosConfig.endpoint_url_production}/users/v1/login`;

                const payload = {
                    username: cpf,
                    password: password,
                    migrate: false
                }

                const headers = {
                    "x-api-key": cartosConfig.api_key,
                    "device_id": `id-${cpf}`
                };

                return eebHelper.http.post(endPoint, payload, headers);
            })

            .then(loginResult => {
                if (loginResult.statusCode !== 200) {
                    throw new Error(`Invalid cartos login result [${JSON.stringify(loginResult)}]`);
                }

                result = {
                    token: loginResult.data.token,
                    refreshToken: loginResult.data.opaqueRefreshTokenId,
                    expire: global.nowMilliseconds(10, 'minutes'), // Salva por 10 minutos...
                };

                const path = getPathAccountToken(cpf, 'login')

                return admin.database().ref(path).set(result);
            })

            .then(_ => {
                if (resultPassword) {
                    result.password = password;
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const changeAccount = (cpf, password, accountId) => {
    return new Promise((resolve, reject) => {
        let userLogin, cartosConfig, result;

        return login(cpf, password)
            .then(loginResult => {
                userLogin = loginResult;

                return secretManager.get('cartos-api-config');
            })

            .then(secretManagerResult => {
                cartosConfig = secretManagerResult;

                const endPoint = `${cartosConfig.endpoint_url_production}/users/v1/login/change-account`;

                const payload = {
                    accountId: accountId
                }

                const headers = {
                    "Authorization": `Bearer ${userLogin.token}`,
                    "x-api-key": cartosConfig.api_key,
                    "device_id": `id-${cpf}-${accountId.substr(0,8)}`
                };

                console.info(headers);

                return eebHelper.http.post(endPoint, payload, headers);

            })

            .then(changeAccountResult => {
                if (!changeAccountResult.statusCode === 200) {
                    throw new Error(`Invalid cartos login result [${JSON.stringify(loginResult)}]`);
                }

                result = changeAccountResult.data;
                result.expire = global.nowMilliseconds(10, 'minutes');

                const path = getPathAccountToken(cpf, accountId)

                return admin.database().ref(path).set(result);
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

            const nowMilliseconds = global.nowMilliseconds();

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    result.refAccountToken = getPathAccountToken(result.parm.cpf, result.parm.accountId);

                    return admin.database().ref(result.refAccountToken).once("value");
                })

                .then(refAccountTokenResult => {

                    refAccountTokenResult = refAccountTokenResult.val() || null;

                    if (
                        refAccountTokenResult &&
                        refAccountTokenResult.token && // Existe um token no cache
                        refAccountTokenResult.expire && // Existe data de expiração
                        nowMilliseconds < refAccountTokenResult.expire // O token é da mesma conta
                    ) {
                        result = {
                            ...result.parm,
                            ...refAccountTokenResult
                        };

                        result.success = true;
                        result.origin = 'buffer';

                        return null;
                    } else {
                        return serviceUserCredential.getByCpf(result.parm.tipo, result.parm.cpf);
                    }

                })

                .then(getByCpfResult => {
                    if (result.success) return null;

                    if (result.parm.accountId === 'login') {
                        return login(getByCpfResult.user, getByCpfResult.password);
                    } else {
                        return changeAccount(getByCpfResult.user, getByCpfResult.password, result.parm.accountId);
                    }
                })

                .then(loginResult => {
                    if (loginResult) {
                        result = {
                            ...result.parm,
                            ...loginResult
                        };

                        result.success = true;
                        result.origin = result.tipo;
                    }

                    return resolve(result);
                })

                .catch(e => {
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

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
