"use strict";

const path = require('path');
const DecimalExtension = require('joi-decimal');
const Joi = require('joi').extend(DecimalExtension);

const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;



const userCredentials = require('./getUserCredential');

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().required(),
        type: Joi.string().valid('STATIC', 'DYNAMIC').required(),
        receiverKey: Joi.string().required(),
        merchantCity: Joi.string().required(),
        value: Joi.when('type', {
            switch: [
                { is: 'STATIC', then: Joi.decimal().greater(0).optional() },
                { is: 'DYNAMIC', then: Joi.decimal().greater(0).required() }
            ]
        }),
        additionalInfo: Joi.string().required()
    });

    return schema;
}

const pixCreate = parm => {
    return new Promise((resolve, reject) => {
        let userLogin, endPoint;

        return userCredentials.call({
            cpf: parm.cpf,
            accountId: parm.accountId
        })

            .then(userCredentialsResult => {
                if (!userCredentialsResult) throw new Error(`Credential not found for ${parm.cpf}`);

                userLogin = userCredentialsResult.result;

                return secretManager.get('cartos-api-config');
            })

            .then(cartosConfig => {
                endPoint = `${cartosConfig.endpoint_url_production}/digital-account/v1/${parm.type === 'DYNAMIC' ? 'pix-dynamic-qrcodes' : 'pix-static-qrcodes'}`;

                let payload = {
                    receiverKey: parm.receiverKey,
                    merchantCity: parm.merchantCity,
                    additionalInfo: parm.additionalInfo
                };

                if (parm.value) {
                    payload.value = parm.value;
                }

                const headers = {
                    "Authorization": `Bearer ${userLogin.token}`,
                    "x-api-key": cartosConfig.api_key,
                    "device_id": `id-${parm.cpf}`
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
                console.error(e);

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

                    return pixCreate(result.parm);
                })

                .then(pixCreateResult => {
                    return resolve(pixCreateResult);
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
        name: 'pix-create',
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
