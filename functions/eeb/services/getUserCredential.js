"use strict";

const admin = require('firebase-admin');
const path = require('path');
const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

const serviceUserCredential = require('../../business/serviceUserCredential');

const schema = _ => {
    const schema = Joi.object({
        tipo: Joi.string().required(),
        cpf: Joi.string().length(11).required()
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

            const result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return serviceUserCredential.getByCpf(result.parm.tipo, result.parm.cpf);
                })
                .then(getByCpfResult => {
                    result.data = getByCpfResult;

                    return resolve(this.parm.async ? { success: true } : result);
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
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'get-user-credential',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.superUser,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
