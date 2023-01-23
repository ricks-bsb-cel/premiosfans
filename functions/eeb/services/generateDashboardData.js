"use strict";

const admin = require('firebase-admin');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');
const moment = require("moment-timezone");

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const schema = _ => {
    const schema = Joi.object({
        path: Joi.string().required(),
        data: Joi.object().required(),
        precision: Joi.string().valid('hour', 'day').default('day')
    });

    return schema;
}

const increment = (original, value) => {
    original = original || 0;
    value = value || 0;

    original = parseFloat(original);
    value = parseFloat(value);

    original = parseFloat((original + value).toFixed(2));

    if (original - parseFloat(Math.floor(original).toFixed(2)) === 0) {
        original = parseInt(original);
    }

    return original;
}

const updatePath = (parms) => {
    return new Promise((resolve, reject) => {
        const hoje = moment().tz("America/Sao_Paulo");
        let result = {}, date;

        if (!parms.path.endsWith('/')) parms.path += '/';
        if (parms.path.startsWith('/')) parms.path = parms.path.substr(1);

        if (parms.precision === 'day') {
            date = hoje.format(parms.dateFormat || 'YYYY-MM-DD');
        } else if (parms.precision === 'hour') {
            date = hoje.format(parms.dateFormat || 'YYYY-MM-DD-HH');
        } else {
            throw new Error(`Invalid precision [${parms.precision}]`);
        }

        parms.path = 'dashboardData/' + parms.path.replace('{date}', date);

        const ref = admin.database().ref(parms.path)

        return ref.transaction(data => {
            data = data || {};

            Object.keys(parms.data).forEach(k => {
                data[k] = increment(data[k], parms.data[k]);
            })

            result = {
                data: data,
                path: parms.path
            };

            return data;
        })

            .then(transactionResult => {
                if (!transactionResult.committed) throw new Error('Transaction error...');

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })
    })
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {

        let result = {
            success: true,
            host: this.parm.host
        };

        return new Promise((resolve, reject) => {

            return schema().validateAsync(this.parm.data)
                .then(dataResult => {

                    const start = dataResult.path.indexOf('{');
                    const end = dataResult.path.indexOf('}');

                    if (
                        (start < 0 && end >= 0) ||
                        (start >= 0 && end < 0) ||
                        (start >= 0 && end >= 0 && end < start)
                    ) {
                        throw new Error('Invalid path. Must contains {date}');
                    }

                    return updatePath(dataResult);
                })

                .then(updateResult => {
                    result = { ...result, ...updateResult };

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
        name: 'generate-dashboard-data',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    if (!request.body) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
