"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../eventBusService').abstract;
const global = require('../../global');

const userCredentials = require('./cartosGetUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../api/firestoreDAL');
const collectionCartosExtract = firestoreDAL.cartosExtract();

/*
    Busca o Extrato da conta na Cartos e atualiza a collection cartosExtract
*/

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().length(36).required()
    });

    return schema;
}

async function getExtract(cpf, accountId, serviceId) {
    const credential = await userCredentials.getCredential(cpf, accountId, serviceId);
    const extract = await cartosHttpRequest.extract(credential.token);

    if (Array.isArray(extract.rows) && extract.rows && extract.rows.length) {
        const promise = [];

        extract.rows.forEach(row => {
            row.cpf = cpf;
            row.serviceId = serviceId;

            global.setDateTime(row, 'dtAtualizacao');

            promise.push(collectionCartosExtract.set(row.transactionId, row));
        })

        await Promise.all(promise);
    }

    return extract;
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
                    return getExtract(dataResult.cpf, dataResult.accountId, this.parm.serviceId);
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
