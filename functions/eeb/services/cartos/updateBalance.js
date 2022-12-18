"use strict";

const path = require('path');
const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;

const userCredentials = require('./getUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosAccounts = firestoreDAL.cartosAccounts();

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
                    return userCredentials.getCredential(dataResult.cpf, dataResult.accountId);
                })

                .then(credential => {
                    return cartosHttpRequest.accounts(credential.token);
                })

                .then(accountsResult => {
                    accounts = accountsResult;

                    // Atualiza o cartosAccounts com as contas existentes
                    const promise = [];

                    accounts.forEach(account => {
                        promise.push(collectionCartosAccounts.merge(account.accountId, account));
                    })

                    return Promise.all(promise);
                })

                .then(_ => {
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
        name: 'update-cartos-data',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        ordered: true,
        orderingKey: accountId,
        auth: eebAuthTypes.tokenNotAnonymous,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
