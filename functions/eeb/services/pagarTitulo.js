"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionTitulos = firestoreDAL.titulos();

const generatePremioTitulo = require('./generatePremioTitulo');
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

const tituloSchema = _ => {
    const schema = Joi.object({
        idTitulo: Joi.string().token().min(18).max(22).required()
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

            return tituloSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.titulo = dataResult;

                    return collectionTitulos.getDoc(result.data.titulo.idTitulo);
                })

                .then(resultTitulo => {

                    result.data.titulo = resultTitulo;

                    if (result.data.titulo.situacao !== 'aguardando-pagamento') {
                        throw new Error('O título não está em situação que permita pagamento');
                    }

                    // Atualiza a situação do titulo
                    result.data.updateTitulo = {
                        situacao: 'pago'
                    };

                    global.setDateTime(result.data.updateTitulo, 'dtPagamento');

                    return collectionTitulos.set(result.data.titulo.id, result.data.updateTitulo, true);
                })

                .then(_ => {

                    // Carrega os premios da campanha do título
                    return collectionCampanhasSorteiosPremios.get({
                        filter: [
                            { field: "idCampanha", condition: "==", value: result.data.titulo.idCampanha }
                        ]
                    })

                })

                .then(resultCampanhaPremios => {

                    if (resultCampanhaPremios.length === 0) {
                        throw new Error('Nenhum premio localizado para a campanha do título');
                    }

                    result.data.campanhaPremios = resultCampanhaPremios;

                    // Solicita a geração dos premios do título de forma asyncrona
                    const promise = [];

                    result.data.campanhaPremios.forEach(p => {
                        promise.push(
                            generatePremioTitulo.call(
                                {
                                    "idCampanha": result.data.titulo.idCampanha,
                                    "idTitulo": result.data.titulo.id,
                                    "idPremio": p.id,
                                    "idSorteio": p.idSorteio
                                }
                            )
                        );
                    });

                    return Promise.all(promise);
                })

                .then(_ => {
                    return resolve(this.parm.async ? { success: true } : result.data.updateTitulo)
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
        name: 'pagar-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {

    // Só pode ser chamado em testes ou entre rotinas
    const host = global.getHost(request);

    if (!request.body || host !== 'localhost') {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
