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

const collectionTitulosPremios = firestoreDAL.titulosPremios();

/*
    checkPremmioTitulo
    - Recebe um id de titulosPremios e verifica se
        - Existe qualquer outro premioTitulo da mesma campanha/premio com um dos números
*/

const premioTituloSchema = _ => {
    const schema = Joi.object({
        idPremioTitulo: Joi.string().token().min(18).max(22).required()
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

            return premioTituloSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.tituloPremio = dataResult;
                    result.data.updateTituloPremio = {
                        checkOk: true,
                        checkError: null,
                        checkConflict: null
                    };

                    global.setDateTime(result.data.updateTituloPremio, 'dtCheck');

                    return collectionTitulosPremios.getDoc(result.data.tituloPremio.idPremioTitulo)
                })

                .then(resultTituloPremio => {
                    result.data.tituloPremio = resultTituloPremio;

                    result.data.idCampanha = result.data.tituloPremio.idCampanha;
                    result.data.idPremio = result.data.tituloPremio.idPremio;

                    if (result.data.tituloPremio.qtdNumerosDaSortePorTitulo !== result.data.tituloPremio.numerosDaSorte.length) {
                        result.data.updateTituloPremio.checkOk = false;
                        result.data.updateTituloPremio.checkError = 'Erro na geração dos números da sorte';

                        return [];
                    }

                    const promise = [];

                    // Procura qualquer outros premios na mesma campanha com o mesmo número
                    // Vai encontrar o mesmo premio que esta sendo validado
                    result.data.tituloPremio.numerosDaSorte.forEach(numero => {
                        promise.push(
                            collectionTitulosPremios.get({
                                filter: [
                                    { field: "idCampanha", condition: "==", value: result.data.idCampanha },
                                    { field: "idPremio", condition: "==", value: result.data.idPremio },
                                    { field: "numerosDaSorte", condition: "array-contains", value: numero }
                                ]
                            })
                        );
                    })

                    return Promise.all(promise);
                })

                .then(resultPromise => {
                    result.data.tituloPremiosConflito = [];

                    resultPromise.forEach(r => {
                        result.data.tituloPremiosConflito = result.data.tituloPremiosConflito.concat(
                            r.filter(f => {
                                // Remove da lista o mesmo prêmmio que está sendo validado
                                return f.id !== result.data.tituloPremio.id;
                            }).map(m => {
                                return {
                                    id: m.id,
                                    idCampanha: m.idCampanha,
                                    idTitulo: m.idTitulo,
                                    idSorteio: m.idSorteio,
                                    idPremio: m.idPremio,
                                    numerosDaSorte: m.numerosDaSorte,
                                    dtInclusao: m.dtInclusao
                                }
                            })
                        );
                    })

                    // Facilita a leitura
                    result.data.tituloPremio = {
                        id: result.data.tituloPremio.id,
                        idCampanha: result.data.tituloPremio.idCampanha,
                        idTitulo: result.data.tituloPremio.idTitulo,
                        idSorteio: result.data.tituloPremio.idSorteio,
                        idPremio: result.data.tituloPremio.idPremio,
                        numerosDaSorte: result.data.tituloPremio.numerosDaSorte,
                        dtInclusao: result.data.tituloPremio.dtInclusao
                    }

                    if (result.data.tituloPremiosConflito.length > 0) {
                        // Erro! Localizou um premio com o mesmo número que não é o mesmo registro
                        result.data.updateTituloPremio.checkOk = false;
                        result.data.updateTituloPremio.checkConflict = result.data.tituloPremiosConflito;
                    }

                    return collectionTitulosPremios.set(
                        result.data.tituloPremio.id,
                        result.data.updateTituloPremio,
                        true
                    );

                })

                .then(_ => {

                    // Envio de alerta aqui!
                    // if(!result.data.updateTituloPremio.checkOk)

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

    const service = new Service(request, response, {
        name: 'check-premio-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        noAuth: true,
        data: data,
        attributes: {
            idEmpresa: 'all'
        }
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
