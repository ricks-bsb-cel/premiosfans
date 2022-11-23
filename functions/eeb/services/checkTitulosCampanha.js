"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const checkTituloCompra = require('./checkTituloCompra');

const collectionCampanhas = firestoreDAL.campanhas();
const collectionTituloCompra = firestoreDAL.titulosCompras();

const parmsSchema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required()
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
                success: true,
                host: this.parm.host,
                data: {}
            };

            return parmsSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data = dataResult;

                    return collectionCampanhas.getDoc(result.data.idCampanha);
                })

                .then(campanha => {
                    result.data.campanha = campanha;

                    return collectionTituloCompra.get({
                        filter: [
                            { field: "idCampanha", condition: "==", value: result.data.idCampanha },
                        ]
                    });
                })

                .then(resultTitulosCompra => {

                    if (resultTitulosCompra.length === 0) {
                        throw new Error(`Nenhuma compra encontrada para a campanha ${result.data.idCampanha}`);
                    }

                    const promise = [];

                    resultTitulosCompra.forEach(t => {
                        promise.push(checkTituloCompra.call({
                            idTituloCompra: t.id
                        }))
                    })

                    return Promise.all(promise);
                })

                .then(promiseResult => {
                    result.data.qtdTitulosCompra = promiseResult.length;

                    delete result.data.campanha;

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
        name: 'check-titulos-campanha',
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
