"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');
const bigQueryAddRow = require('./bigquery/bigqueryAddRow');

const pagarTitulo = require('./pagarTitulo');

const collectionTitulosCompras = firestoreDAL.titulosCompras();
const collectionTitulos = firestoreDAL.titulos();
const collectionCartosPix = firestoreDAL.cartosPix();
const collectionInfluencer = firestoreDAL.influencers();

const acompanhamentoTituloCompra = require('./acompanhamentoTituloCompra');

const tituloCompraSchema = _ => {
    const schema = Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required(),
        cartosPixId: Joi.string().token().min(18).max(22).optional()
    });

    return schema;
}

const toBigQueryTableComprasPagas = (compra, cartosPix, influencer) => {
    const data = {
        idCompra: compra.id,
        idCampanha: compra.idCampanha,

        idInfluencer: compra.idInfluencer,
        influencerNome: influencer.nome,
        influencerEmail: influencer.email || null,
        influencerCelular: influencer.celular || null,

        qtdPremios: compra.qtdPremios,
        campanhaQtdNumerosDaSortePorTitulo: compra.campanhaQtdNumerosDaSortePorTitulo,
        campanhaNome: compra.campanhaNome,
        campanhaSubTitulo: compra.campanhaSubTitulo,
        campanhaDetalhes: compra.campanhaDetalhes,
        campanhaVlTitulo: compra.campanhaVlTitulo,
        vlTotalCompra: parseFloat(compra.vlTotalCompra.toFixed(2)),
        campanhaQtdPremios: compra.campanhaQtdPremios,
        campanhaTemplate: compra.campanhaTemplate,
        guidCompra: compra.guidCompra,
        qtdTitulosCompra: compra.qtdTitulosCompra,
        uidComprador: compra.uidComprador,

        pixKeyCredito: compra.pixKeyCredito,
        pixKeyCpf: compra.pixKeyCpf,
        pixKeyAccountId: compra.pixKeyAccountId,
        qtdTotalProcessos: compra.qtdTotalProcessos,

        compradorCPF: compra.cpf,
        compradorNome: compra.nome,
        compradorEmail: compra.email,
        compradorCelular: compra.celular,

        pagamentoManual: true,
        dtPagamento: global.getToday()
    };

    if (cartosPix) {
        data.pagamentoManual = false;
        data.dtPagamento = cartosPix.cartosPixPago_createdAt;

        data.idCartosPix = cartosPix.id;

        data.payerAccount = cartosPix.cartosPixPago_accountPayer;
        data.payerAgency = cartosPix.cartosPixPago_agencyPayer;
        data.payerBankIspb = cartosPix.cartosPixPago_bankIspbPayer;
        data.payerClientName = cartosPix.cartosPixPago_clientNamePayer;
        data.payerDescription = cartosPix.cartosPixPago_description;
        data.payerDocument = cartosPix.cartosPixPago_documentPayer;
        data.payerOperationNumber = cartosPix.cartosPixPago_operationNumber;
        data.payerTxId = cartosPix.cartosPixPago_txId;
    }

    // Estrutura da tabela
    return {
        "tableType": "bigQueryTableComprasPagas",
        "datasetId": "campanha_" + compra.idCampanha,
        "tableName": "comprasPagas",
        "row": data
    };
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

                    // Se informado o registor do cartosPixPago
                    if (result.data.tituloCompra.cartosPixId) {
                        promise.push(collectionCartosPix.getDoc(result.data.tituloCompra.cartosPixId));
                    }

                    return Promise.all(promise);
                })

                .then(promiseResult => {

                    result.data.tituloCompra = promiseResult[0];
                    result.data.titulos = promiseResult[1];
                    result.data.cartosPix = promiseResult[2] || null;

                    if (result.data.tituloCompra.situacao !== 'aguardando-pagamento') {
                        throw new Error('A compra não está aguardando pagamento');
                    }

                    if (result.data.titulos.length === 0) {
                        throw new Error('A compra não possui nenhum título aguardando pagamento');
                    }

                    // Busca os dados do influencer
                    return collectionInfluencer.getDoc(result.data.tituloCompra.idInfluencer);
                })

                .then(resultInfluencer => {
                    result.data.influencer = resultInfluencer;

                    // Atualiza a situação do titulo
                    result.data.updateTituloCompra = {
                        situacao: 'pago',
                        pagamentoManual: (result.data.cartosPixId === null)
                    };

                    global.setDateTime(result.data.updateTituloCompra, 'dtPagamento');

                    return collectionTitulosCompras.set(result.data.tituloCompra.id, result.data.updateTituloCompra, true);
                })

                .then(_ => {

                    // Solicita o pagamento de cada um dos Títulos (que vai solicitar a geração dos números)
                    promise = [acompanhamentoTituloCompra.setPago(result.data.tituloCompra)];

                    result.data.titulos.forEach(p => {
                        promise.push(pagarTitulo.call({ "idTitulo": p.id }));
                    });

                    // Adiciona também o registro do TituloCompra pago em bigQueryTableComprasPagas
                    promise.push(bigQueryAddRow.call(
                        toBigQueryTableComprasPagas(
                            result.data.tituloCompra,
                            result.data.cartosPix,
                            result.data.influencer
                        )
                    )
                    );

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
