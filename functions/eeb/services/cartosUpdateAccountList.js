"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../eventBusService').abstract;
const global = require('../../global');

const userCredentials = require('./cartosGetUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../api/firestoreDAL');
const collectionCartosAccounts = firestoreDAL.cartosAccounts();

/*
    Busca todas as contas de um CPF na Cartos e atualiza a collection cartosAccounts
*/

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().length(11).required()
    });

    return schema;
}

async function updateAccountList(cpf, serviceId) {

    const credential = await userCredentials.getCredential(cpf, 'any');
    const accounts = await cartosHttpRequest.accounts(credential.token);

    // Atualiza o cartosAccounts com as contas existentes
    const promise = [];

    accounts.forEach(account => {
        account.cpf = cpf;
        account.serviceId = serviceId;

        global.setDtHoje(account, 'dtAtualizacao');

        promise.push(collectionCartosAccounts.merge(account.accountId, account));
    })

    await Promise.all(promise);

    return accounts;
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
                    return updateAccountList(dataResult.cpf, this.parm.serviceId);
                })

                .then(accounts => {
                    return resolve(this.parm.async ? { success: true } : accounts);
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
