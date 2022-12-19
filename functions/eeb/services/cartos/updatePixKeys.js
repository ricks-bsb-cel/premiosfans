"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;
const global = require('../../../global');

const userCredentials = require('./getUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosPixKeys = firestoreDAL.cartosPixKeys();

/*
    Busca as chaves PIX da conta na Cartos e atualiza a collection cartosAccountsPixKeys
*/

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().length(36).required()
    });

    return schema;
}

async function getPixKeys(cpf, accountId) {
    const credential = await userCredentials.getCredential(cpf, accountId);
    const pixKeys = await cartosHttpRequest.pixKeys(credential.token);

    if (Array.isArray(pixKeys) && pixKeys.length) {
        const promise = [];

        pixKeys.forEach(row => {
            row.cpf = cpf;
            global.setDateTime(row, 'dtAtualizacao');

            promise.push(collectionCartosPixKeys.set(row.key, row));
        })

        await Promise.all(promise);
    }

    return pixKeys;
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
                    return getPixKeys(dataResult.cpf, dataResult.accountId);
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
    const eebAuthTypes = require('../../eventBusService').authType;

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
