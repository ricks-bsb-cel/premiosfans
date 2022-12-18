"use strict";

const path = require('path');
const Joi = require('joi');
const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;

const userCredentials = require('./getUserCredential');
const accountList = require('./accountList');

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().required(),
        type: Joi.string().valid('EMAIL', 'CPF_CNPJ', 'PHONE', 'EVP').required(),
        key: Joi
            .when('type', {
                switch: [
                    { is: 'CPF_CNPJ', then: Joi.string().min(11).max(14).required() },
                    { is: 'EMAIL', then: Joi.string().email().required() },
                    { is: 'PHONE', then: Joi.string().length(10).pattern(/^[0-9]+$/).required() }
                ],
                otherwise: Joi.forbidden()
            }),
        typeAccount: Joi.string().valid('CACC', 'SVGS', 'SLRY').default('CACC').optional()
    });

    return schema;
}

const createPixKey = (parm, accountData) => {
    return new Promise((resolve, reject) => {
        let userLogin, endPoint;

        return userCredentials.call({
            cpf: parm.cpf,
            accountId: accountData.accountId
        })

            .then(userCredentialsResult => {
                if (!userCredentialsResult) throw new Error(`Credential not found for ${cpf}`);

                userLogin = userCredentialsResult.result;

                return secretManager.get('cartos-api-config');
            })

            .then(cartosConfig => {
                endPoint = `${cartosConfig.endpoint_url_production}/digital-account/v1/pix-keys`;

                let payload = {
                    type: parm.type,
                    agency: accountData.agency,
                    openingDate: accountData.createdAt,
                    typeAccount: parm.typeAccount,
                    typeOwner: accountData.personType === "PJ" ? "LEGAL_PERSON" : "NATURAL_PERSON"
                };

                if (parm.type !== "EVP") {
                    payload.key = parm.key;
                }

                const headers = {
                    "Authorization": `Bearer ${userLogin.token}`,
                    "x-api-key": cartosConfig.api_key,
                    "device_id": `id-${payload.cpf}`
                };

                return eebHelper.http.post(endPoint, payload, headers);
            })

            .then(getResult => {
                if (getResult.statusCode !== 200) {
                    throw new Error(`Invalid result: ${JSON.stringify(getResult)}`);
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

                    return accountList.call({
                        cpf: result.parm.cpf,
                        accountId: result.parm.accountId
                    });
                })

                .then(accountListResult => {
                    if (!accountListResult.result) {
                        throw new Error(`Conta [${result.parm.accountId}] não encontrada`);
                    }

                    return createPixKey(
                        result.parm,
                        accountListResult.result
                    );
                })

                .then(createPixKeyResult => {
                    return resolve(createPixKeyResult);
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
        name: 'pix-keys-create',
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
