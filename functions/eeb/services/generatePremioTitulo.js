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

const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();
const collectionCampanhasSorteios = firestoreDAL.campanhasSorteios();
const collectionTitulos = firestoreDAL.titulos();
const collectionTitulosPremios = firestoreDAL.titulosPremios();

/*
    generatePremioTitulo
    - Recebe idTitulo, idCampanha e idPremio
    - Verifica se o premio já não foi gerado
    - Gera o premio da campanha (sem gerar os números da sorte)
    - Solicita que os números da sorte sejam gerados para o premio do título
*/

const premioTituloSchema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        idTitulo: Joi.string().token().min(18).max(22).required(),
        idPremio: Joi.string().token().min(18).max(22).required(),
        idSorteio: Joi.string().token().min(18).max(22).required()
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

                    const promise = [
                        collectionTitulos.getDoc(result.data.tituloPremio.idTitulo),
                        collectionCampanhasSorteiosPremios.getDoc(result.data.tituloPremio.idPremio),
                        collectionCampanhasSorteios.getDoc(result.data.tituloPremio.idSorteio)
                    ];

                    return Promise.all(promise);
                })

                .then(promiseResult => {
                    result.data.titulo = promiseResult[0];
                    result.data.premio = promiseResult[1];
                    result.data.sorteio = promiseResult[2];

                    if (result.data.titulo.idCampanha !== result.data.tituloPremio.idCampanha) throw new Error(`O título ${result.data.titulo.idTitulo} não pertence à campanha ${result.data.titulo.idCampanha}`);
                    if (result.data.premio.idCampanha !== result.data.tituloPremio.idCampanha) throw new Error(`O premio ${result.data.premio.idTitulo} não pertence à campanha ${result.data.titulo.idCampanha}`);
                    if (result.data.titulo.idCampanha !== result.data.premio.idCampanha) throw new Error(`A campanha do título ${result.data.titulo.idTitulo} não pertence ao premio ${result.data.premio.idCampanha}`);
                    if (result.data.titulo.idCampanha !== result.data.sorteio.idCampanha) throw new Error(`A campanha do título ${result.data.titulo.idTitulo} não pertence ao sorteio ${result.data.sorteio.idCampanha}`);

                    // Verifica se o tituloPremio já não foi criado
                    return collectionTitulosPremios.get({
                        filter: [
                            { field: "idCampanha", condition: "==", value: result.data.tituloPremio.idCampanha },
                            { field: "idTitulo", condition: "==", value: result.data.tituloPremio.idTitulo },
                            { field: "idPremio", condition: "==", value: result.data.tituloPremio.idPremio }
                        ]
                    });
                })

                .then(resultTituloPremio => {

                    if (resultTituloPremio.length) {
                        return resultTituloPremio[0];
                    }

                    // Dados do Prêmio
                    result.data.tituloPremio.premioDescricao = result.data.premio.descricao;
                    result.data.tituloPremio.premioValor = result.data.premio.valor;
                    result.data.tituloPremio.numerosDaSorte = [];

                    // Dados do Sorteio
                    result.data.tituloPremio.sorteioDtSorteio = result.data.sorteio .dtSorteio;
                    result.data.tituloPremio.sorteioDtSorteio_timestamp = result.data.sorteio .dtSorteio_timestamp;
                    result.data.tituloPremio.sorteioDtSorteio_weak_day = result.data.sorteio .dtSorteio_weak_day;
                    result.data.tituloPremio.sorteioDtSorteio_yyyymmdd = result.data.sorteio .dtSorteio_yyyymmdd;

                    global.setDateTime(result.data.tituloPremio, 'dtInclusao');

                    return collectionTitulosPremios.add(result.data.tituloPremio);
                })

                .then(saveResult => {
                    result.data.tituloPremio = saveResult;

                    result.data = { tituloPremio: result.data.tituloPremio };

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
    if (!data.idCampanha) {
        throw new Error('invalid parm');
    }

    const service = new Service(request, response, {
        name: 'generate-premio-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        noAuth: true,
        data: data,
        attributes: {
            idEmpresa: data.idCampanha
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {

    const host = global.getHost(request);

    if (!request.body || host !== 'localhost') {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
