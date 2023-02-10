"use strict";

const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;

const firestoreDAL = require('../../../api/firestoreDAL');

const bigqueryHelper = require('./bigqueryHelper');

const schema = _ => {
    return Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required()
    });
}

const tableSchemaTest = {
    schema: [
        { name: 'nome', type: 'STRING', mode: 'REQUIRED' },
        { name: 'idade', type: 'INTEGER', mode: 'REQUIRED' },
        { name: 'cidade', type: 'STRING', mode: 'NULLABLE' },
        { name: 'estado', type: 'STRING', mode: 'NULLABLE' },
    ]
};

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {
            const result = {};

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    return Promise.all([
                        bigqueryHelper.getDataSet('test', 'test', tableSchemaTest),
                        bigqueryHelper.getDataSet('test', 'test5', tableSchemaTest),
                        bigqueryHelper.getDataSet('test', 'test6', tableSchemaTest)
                    ])
                })

                .then(result => {
                    return resolve(this.parm.async ? { success: true } : result);
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
        name: 'bigquery-save-compra-concluida',
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
