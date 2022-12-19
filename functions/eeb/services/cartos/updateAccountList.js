"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;

const userCredentials = require('./getUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
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

async function updateAccountList(cpf) {

    const credential = await userCredentials.getCredential(cpf, 'any');
    const accounts = await cartosHttpRequest.accounts(credential.token);

    // Atualiza o cartosAccounts com as contas existentes
    const promise = [];

    accounts.forEach(account => {
        account.cpf = cpf;
        
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

            let accounts;

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    return updateAccountList(dataResult.cpf);
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
    const eebAuthTypes = require('../../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'update-account-list',
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
