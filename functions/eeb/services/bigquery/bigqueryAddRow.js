"use strict";

const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;

const bigqueryHelper = require('./bigqueryHelper');

const schema = _ => {
    return Joi.object({
        tableType: Joi.string().min(1).max(128).required(),
        datasetId: Joi.string().min(1).max(128).required(),
        tableName: Joi.string().min(1).max(128).required(),
        row: Joi.object(),
        rows: Joi.array().items(Joi.object()).min(1)
    }).xor('row', 'rows').required();
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {
        const dataResult = await schema().validateAsync(this.parm.data);
        const result = await bigqueryHelper.addRow(dataResult);

        return this.parm.async ? { success: true } : result;
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'bigquery-add-row',
        async: request && request.query.async ? request.query.async === 'true' : true,
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
