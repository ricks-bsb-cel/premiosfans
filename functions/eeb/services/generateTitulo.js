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

const collectionCampanhas = firestoreDAL.campanhas();
const collectionInfluencers = firestoreDAL.influencers();
const collectionCampanhasInfluencers = firestoreDAL.campanhasInfluencers();
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();
const collectionTitulos = firestoreDAL.titulos();

/*
    generateTitulo
    - Valida o token do cliente
    - Valida os dados do cliente
    - Verifica as configurações da campanha
    - Gera o registro do título
    - NÃO GERA OS PRÊMIOS DO TÍTULO. Isso será feito após o pagamento.

    * Lembre-se! Cada vez que esta rotina é executada um novo títuo é gerado!
*/

const clienteSchema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        idInfluencer: Joi.string().token().min(18).max(22).required(),
        nome: Joi.string().min(6).max(120).required(),
        email: Joi.string().email().required(),
        celular: Joi.string().replace(' ', '').length(11).pattern(/^[0-9]+$/).required(),
        cpf: Joi.string().replace(' ', '').length(11).pattern(/^[0-9]+$/).required()
    });

    return schema;
}

const sanitizeData = data => {

    if (!global.isCPFValido(data.cpf)) throw new Error(`CPF inválido`);

    const celular = global.formatPhoneNumber(data.celular);

    data.celular_int = celular.phoneNumber_int;
    data.celular_intplus = celular.phoneNumber_intplus;
    data.celular_formated = celular.celularFormated;

    data.cpf_formated = global.formatCpf(data.cpf);

    data.cpf_hide = global.hideCpf(data.cpf);
    data.email_hide = global.hideEmail(data.email);
    data.celular_hide = global.hideCelular(data.celular);

    data.guidTitulo = global.guid();

    global.setDateTime(data, 'dtInclusao');

    return data;

}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let promise;

            const result = {
                success: true,
                host: this.parm.host,
                data: {}
            };

            return clienteSchema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.titulo = sanitizeData(dataResult);

                    promise = [
                        collectionCampanhas.getDoc(result.data.titulo.idCampanha),
                        collectionInfluencers.getDoc(result.data.titulo.idInfluencer),
                        collectionCampanhasInfluencers.get({
                            filter: [
                                { field: "idCampanha", condition: "==", value: result.data.titulo.idCampanha },
                                { field: "idInfluencer", condition: "==", value: result.data.titulo.idInfluencer },
                                { field: "selected", condition: "==", value: true }
                            ]
                        }),
                        collectionCampanhasSorteiosPremios.get({
                            filter: [
                                { field: "idCampanha", condition: "==", value: result.data.titulo.idCampanha }
                            ]
                        })
                    ];

                    return Promise.all(promise);
                })

                .then(promiseResult => {
                    result.data.campanha = promiseResult[0];
                    result.data.influencer = promiseResult[1];
                    result.data.campanhaInfluencer = promiseResult[2];
                    result.data.campanhaPremios = promiseResult[3];

                    if (result.data.campanhaInfluencer.length !== 1) {
                        throw new Error(`Influencer ${result.data.idInfluencer} não vinculado à campanha ${result.data.idCampanha}`);
                    }

                    result.data.campanhaInfluencer = result.data.campanhaInfluencer[0];

                    result.data.titulo.qtdPremios = result.data.campanhaPremios.length;
                    result.data.titulo.qtdNumerosDaSortePorTitulo = result.data.campanha.qtdNumerosDaSortePorTitulo;
                    result.data.titulo.campanhaNome = result.data.campanha.titulo;
                    result.data.titulo.campanhaSubTitulo = result.data.campanha.subTitulo;
                    result.data.titulo.campanhaDetalhes = result.data.campanha.detalhes;
                    result.data.titulo.campanhaVlTitulo = result.data.campanha.vlTitulo;
                    result.data.titulo.campanhaQtdPremios = result.data.campanha.qtdPremios;
                    result.data.titulo.campanhaTemplate = result.data.campanha.template;

                    result.data.titulo.situacao = 'aguardando-pagamento';

                    result.data.titulo.uidComprador = this.parm.attributes.uid;

                    return collectionTitulos.add(result.data.titulo);
                })

                .then(_ => {
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
        name: 'generate-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        noAuth: false, // Autenticação Obrigatória
        authAnonymous: true, // Pode ser usuário Anonimo
        data: data,
        attributes: {
            idEmpresa: data.idCampanha
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
