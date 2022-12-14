"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;
const Joi = require('joi');
const global = require('../../../global');

const serviceUserCredential = require('../../../business/serviceUserCredential');

const schema = _ => {
    const schema = Joi.object({
        tipo: Joi.string().default('cartos').optional(),
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().default('login').optional()
    });

    return schema;
}

const login = (cpf, password) => {
    return new Promise((resolve, reject) => {
        return global.config.get('cartos/endpoint')
            .then(cartosEndPoint=>{
                const endPoint = `${cartosEndPoint}/users/v1/login`;

                const payload = {
                    username: username,
                    password: password,
                    migrate: false
                }

                const headers = {
                    "x-api-key": this.config.api_key,
                    "device_id": uid
                };

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
                success: true
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

                        return null;
                    } else {
                        return this.changeAccount(uid, accountId);
                    }

                    return serviceUserCredential.getByCpf(result.parm.tipo, result.parm.cpf);
                })
                .then(getByCpfResult => {
                    result.data = getByCpfResult;

                    return global.config.get('cartos/endpoint');
                }
                .then(cartosEndPoint => {

                    const username = result.data.user;
                    const password = result.data.password;




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
        async: request && request.query.async ? request.query.async === 'true' : false,
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
