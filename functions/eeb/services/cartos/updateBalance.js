"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;
const global = require('../../../global');

const userCredentials = require('./getUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosBalance = firestoreDAL.cartosBalance();

/*
    Busca o Balance da conta na Cartos e atualiza a collection cartosBalance
*/

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().length(36).required()
    });

    return schema;
}

async function getBalance(cpf, accountId) {
    const credential = await userCredentials.getCredential(cpf, accountId);
    const balance = await cartosHttpRequest.balance(credential.token);

    balance.cpf = cpf;
    balance.accountId = accountId;

    global.setDateTime(balance, 'dtAtualizacao');

    await collectionCartosBalance.set(balance.accountId, balance);

    return balance;
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
                    return getBalance(dataResult.cpf, dataResult.accountId);
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
