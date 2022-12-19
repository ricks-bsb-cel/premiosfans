"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../eventBusService').abstract;
const global = require('../../global');

const userCredentials = require('./cartosGetUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../api/firestoreDAL');
const collectionCartosPix = firestoreDAL.cartosPix();

/*
    Cria um PIX para pagamento e o salva na collection cartosPix
*/

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().required(),
        type: Joi.string().valid('STATIC', 'DYNAMIC').required(),
        receiverKey: Joi.string().required(),
        merchantCity: Joi.string().required(),
        value: Joi.when('type', {
            switch: [
                { is: 'STATIC', then: Joi.number().positive().optional() },
                { is: 'DYNAMIC', then: Joi.number().positive().required() }
            ]
        }),
        additionalInfo: Joi.string().required()
    });

    return schema;
}

async function generatePix(data) {
    const credential = await userCredentials.getCredential(data.cpf, data.accountId);
    const pix = await cartosHttpRequest.generatePix(data, credential.token);

    global.setDateTime(pix, 'dtInclusao');

    await collectionCartosPix.add(pix)

    return pix;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    return generatePix(dataResult);
                })

                .then(balance => {
                    return resolve(this.parm.async ? { success: true } : balance);
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    if (!data.cpf) throw new Error('o CPF é obrigatório...');

    const service = new Service(request, response, {
        name: 'update-cartos-data',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        ordered: true,
        orderingKey: data.cpf,
        auth: eebAuthTypes.tokenNotAnonymous,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
