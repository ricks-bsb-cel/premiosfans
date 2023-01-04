"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanha = firestoreDAL.campanhas();
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

const generateNumeroDaSortePremio = require('./generateNumerosDaSortePremio');

const ativarCampanhaSchema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required()
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

            return ativarCampanhaSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data = {
                        ...result.data,
                        ...dataResult
                    };

                    const promise = [
                        collectionCampanha.getDoc(result.data.idCampanha),
                        collectionCampanhasSorteiosPremios.get({
                            filter: [
                                { field: "idCampanha", condition: "==", value: result.data.idCampanha },
                            ]
                        })
                    ];

                    return Promise.all(promise);
                })

                .then(promiseResult => {
                    result.data.campanha = promiseResult[0];
                    result.data.sorteiosPremios = promiseResult[1];

                    if (result.data.campanha.ativo) {
                        throw new Error(`A campanha ${result.data.idCampanha} já está ativa`);
                    }

                    // Passa a campanha para ativa
                    const updateCampanha = {
                        ativo: true,
                        qtdPremiosNumerosDaSorteGerados: 0
                    };

                    global.setDateTime(updateCampanha, 'dtAtivacao');

                    return collectionCampanha.set(result.data.idCampanha, updateCampanha, true);
                })

                .then(_ => {

                    const promise = [];

                    result.data.sorteiosPremios.forEach(s => {
                        promise.push(
                            generateNumeroDaSortePremio.call({
                                idCampanha: result.data.idCampanha,
                                idPremio: s.id,
                                qtdGrupos: result.data.campanha.qtdGrupos,
                                qtdNumerosPorGrupo: result.data.campanha.qtdNumerosPorGrupo
                            })
                        )
                    });

                    return Promise.all(promise);
                })

                .then(_ => {

                    delete result.data.campanha;

                    result.data.sorteiosPremios = result.data.sorteiosPremios.map(p => {
                        return {
                            idSorteio: p.idSorteio,
                            id: p.id
                        }
                    })


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

    if (!data.idCampanha) {
        throw new Error('invalid parm');
    }

    const service = new Service(request, response, {
        name: 'ativar-campanha',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.tokenNotAnonymous
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
