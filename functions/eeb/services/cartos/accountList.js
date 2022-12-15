"use strict";

const path = require('path');
const Joi = require('joi');
const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;

const userCredentials = require('./getUserCredential');

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().optional()
    });

    return schema;
}

const accounts = cpf => {
    return new Promise((resolve, reject) => {

        let userLogin;

        return userCredentials.call({
            cpf: cpf
        })
            .then(userCredentialsResult => {
                if (!userCredentialsResult) throw new Error(`Credential not found for ${cpf}`);

                userLogin = userCredentialsResult.result;

                return secretManager.get('cartos-api-config');
            })

            .then(cartosConfig => {
                const endPoint = `${cartosConfig.endpoint_url_production}/digital-account/v1/accounts?typeRequest=byCpfHash`;

                const headers = {
                    "Authorization": `Bearer ${userLogin.token}`,
                    "x-api-key": cartosConfig.api_key,
                    "device_id": cpf
                };

                return eebHelper.http.get(endPoint, headers);
            })

            .then(getResult => {
                if (getResult.statusCode !== 200) {
                    throw new Error(`Invalid result [${JSON.stringify(getResult)}]`);
                }

                return resolve(getResult.data);
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

                    return accounts(result.parm.cpf);
                })

                .then(accountsResult => {
                    if (result.parm.accountId) {
                        accountsResult = accountsResult.filter(f => {
                            return f.accountId === result.parm.accountId;
                        })

                        if (accountsResult.length) {
                            accountsResult = accountsResult[0];
                        } else {
                            accountsResult = null;
                        }
                    }

                    return resolve(accountsResult);
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
        name: 'account-list',
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
