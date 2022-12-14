"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;
const Joi = require('joi');
const global = require('../../../global');
const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');

const serviceUserCredential = require('../../../business/serviceUserCredential');
const { executionAsyncResource } = require('async_hooks');

const schema = _ => {
    const schema = Joi.object({
        tipo: Joi.string().default('cartos').optional(),
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().default('login').optional()
    });

    return schema;
}

const getPathAccountToken = (cpf, accountId) => {
    return `/tokens/${result.parm.cpf}/cartos/${result.parm.accountId}`;
}

const login = (cpf, password) => {
    return new Promise((resolve, reject) => {

        let result;

        return secretManager.get('cartos-api-config')
            .then(cartosConfig => {
                const endPoint = `${cartosConfig.endpoint_url_production}/users/v1/login`;

                const payload = {
                    username: cpf,
                    password: password,
                    migrate: false
                }

                const headers = {
                    "x-api-key": cartosConfig.api_key,
                    "device_id": cpf
                };

                return eebHelper.http.post(endPoint, payload, headers);
            })

            .then(loginResult => {
                if (!loginResult.statusCode === 200) {
                    throw new Error(`Invalid cartos login result [${JSON.stringify(loginResult)}]`);
                }

                const result = {
                    token: loginResult.data.token,
                    refreshToken: loginResult.data.opaqueRefreshTokenId,
                    expire: global.nowMilliseconds(10, 'minutes'), // Salva por 10 minutos...
                };

                const path = getPathAccountToken(cpf, 'login')

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

            const result = {
                success: false
            };

            const nowMilliseconds = global.nowMilliseconds();

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    result.refAccountToken = `/tokens/${result.parm.cpf}/cartos/${result.parm.accountId}`;

                    return admin.database().ref(result.refAccountToken).once("value");
                })

                .then(refAccountTokenResult => {

                    resultRefToken = refAccountTokenResult.val() || null;

                    if (resultRefToken && // Existe um token no cache
                        resultRefToken.expire && // Existe data de expiração
                        nowMilliseconds < resultRefToken.expire && // Não expirou
                        resultRefToken.accountId === result.parm.accountId // O token é da mesma conta
                    ) {
                        result.accountResult = resultRefToken;
                        result.accountResult.origin = 'buffer';
                        result.success = true;

                        return null;
                    } else {
                        return serviceUserCredential.getByCpf(result.parm.tipo, result.parm.cpf);
                    }

                })

                .then(getByCpfResult => {
                    if (result.success) return null;

                    return login(getByCpfResult.user, getByCpfResult.password);
                })

                .then(loginResult => {
                    if (loginResult) {
                        result = loginResult;
                        result.success = true;
                    }

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    console.error(e);

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
