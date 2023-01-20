"use strict";

const pixStoreHelper = require('./pixStoreHelper');

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const schema = _ => {
    const schema = Joi.object({
        key: Joi.string().required(),
        valor: Joi.number().min(1).max(999999).required()
    });

    return schema;
}


class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return pixStoreHelper.findNotUsedPix(result.parm.key, result.parm.valor);
                })

                .then(findNotUsedPixResult => {
                    console.info('result', findNotUsedPixResult);

                    result.data = findNotUsedPixResult;

                    return resolve(result);
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
        name: 'pix-store-get-not-used-pix',
        async: false,
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
