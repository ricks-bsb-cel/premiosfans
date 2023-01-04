"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const pagarTitulo = require('./pagarTitulo');

const collectionTitulosCompras = firestoreDAL.titulosCompras();
const collectionTitulos = firestoreDAL.titulos();

const tituloCompraSchema = _ => {
    const schema = Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required()
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

            const result = {
                success: true,
                host: this.parm.host,
                data: {}
            };

            let promise = [];

            return tituloCompraSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.tituloCompra = dataResult;

                    promise = [
                        collectionTitulosCompras.getDoc(result.data.tituloCompra.idTituloCompra),
                        collectionTitulos.get({
                            filter: [
                                { field: "idTituloCompra", condition: "==", value: result.data.tituloCompra.idTituloCompra },
                                { field: "situacao", condition: "==", value: "aguardando-pagamento" }
                            ]
                        })
                    ];

                    return Promise.all(promise);
                })

                .then(promiseResult => {

                    result.data.tituloCompra = promiseResult[0];
                    result.data.titulos = promiseResult[1];

                    if (result.data.tituloCompra.situacao !== 'aguardando-pagamento') {
                        throw new Error('A compra não está aguardando pagamento');
                    }

                    if (result.data.titulos.length === 0) {
                        throw new Error('A compra não possui nenhum título aguardando pagamento');
                    }

                    // Atualiza a situação do titulo
                    result.data.updateTituloCompra = {
                        situacao: 'pago'
                    };

                    global.setDateTime(result.data.updateTituloCompra, 'dtPagamento');

                    return collectionTitulosCompras.set(result.data.tituloCompra.id, result.data.updateTituloCompra, true);
                })

                .then(_ => {

                    // Solicita o pagamento de cada um dos Títulos (que vai solicitar a geração dos números)
                    promise = [];

                    result.data.titulos.forEach(p => {
                        promise.push(
                            pagarTitulo.call(
                                {
                                    "idTitulo": p.id
                                }
                            )
                        );
                    });

                    return Promise.all(promise);
                })

                .then(_ => {
                    return resolve(this.parm.async ? { success: true } : result.data.updateTituloCompra)
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
        name: 'pagar-compra',
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
