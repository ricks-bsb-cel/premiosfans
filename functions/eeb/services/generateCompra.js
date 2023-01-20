"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

const pixStoreHelper = require('./pixStoreHelper');

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
const collectionTitulosCompras = firestoreDAL.titulosCompras();

const generatePedidoPagamentoCompra = require('./generatePedidoPagamentoCompra');
const acompanhamentoTituloCompra = require('./acompanhamentoTituloCompra');

/*
    generateTitulo
    - Valida o token do cliente
    - Valida os dados do cliente
    - Verifica as configurações da campanha
    - Gera o registro de Compra e dos títulos
    - NÃO GERA OS PRÊMIOS DO TÍTULO. Isso será feito após o pagamento.

    - Esta rotina além de gerar a compra também prepara os títulos (mas não vincula os números)

    20/01/2023
    - Uso do PIX Storage. Procura por lá um PIX com a mesma chave/valor ainda não utilizado.
    - Se achar, não solicita o generatePedidoPagamentoCompra, já chama o acompanhamentoTituloCompra.setPixData

*/

const schema = _ => {
    return Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        idInfluencer: Joi.string().token().min(18).max(22).required(),
        nome: Joi.string().min(6).max(120).required(), // O nome do Cliente
        email: Joi.string().email().required(), // O email do Cliente
        celular: Joi.string().replace(' ', '').length(11).pattern(/^[0-9]+$/).required(), // O celular do Cliente (apenas números)
        cpf: Joi.string().replace(' ', '').length(11).pattern(/^[0-9]+$/).required(), // O CPF do Cliente (apenas números)
        qtdTitulos: Joi.number().min(1).max(6).required() // A quantidade de títulos que o cliente deseja
    });
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

    return data;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let promise;

            const result = {
                success: true,
                host: this.parm.host,
                qtdTitulos: 0,
                data: {}
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.titulo = sanitizeData(dataResult);
                    result.qtdTitulos = result.data.titulo.qtdTitulos;

                    delete result.data.titulo.qtdTitulos;

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

                    if (!result.data.campanha.ativo) {
                        throw new Error(`A campanha ${result.data.titulo.idCampanha} não está ativa`);
                    }

                    if (result.data.campanhaInfluencer.length !== 1) {
                        throw new Error(`Influencer ${result.data.idInfluencer} não vinculado à campanha ${result.data.idCampanha}`);
                    }

                    result.data.campanhaInfluencer = result.data.campanhaInfluencer[0];

                    // Registro da Compra (tituloCompra)
                    result.data.compra = {
                        idCampanha: result.data.titulo.idCampanha,
                        idInfluencer: result.data.titulo.idInfluencer,
                        qtdPremios: result.data.campanhaPremios.length,
                        campanhaQtdNumerosDaSortePorTitulo: result.data.campanha.qtdNumerosDaSortePorTitulo,
                        campanhaNome: result.data.campanha.titulo,
                        campanhaSubTitulo: result.data.campanha.subTitulo || '',
                        campanhaDetalhes: result.data.campanha.detalhes || '',
                        campanhaVlTitulo: parseFloat(result.data.campanha.vlTitulo),
                        campanhaQtdPremios: parseInt(result.data.campanha.qtdPremios),
                        campanhaTemplate: result.data.campanha.template,
                        situacao: 'aguardando-pagamento',
                        guidCompra: global.guid(),
                        qtdTitulosCompra: parseInt(result.qtdTitulos),
                        uidComprador: this.parm.attributes.user_uid,
                        qtdNumerosGerados: 0,
                        pixKeyCredito: result.data.campanha.pixKeyCredito,
                        pixKeyCpf: result.data.campanha.pixKeyCredito_cpf,
                        pixKeyAccountId: result.data.campanha.pixKeyCredito_accountId,
                        qtdTotalProcessos:
                            ( // Cada título gera seus próprios premios
                                parseInt(result.qtdTitulos) * parseInt(result.data.campanha.qtdPremios)
                            ) +
                            ( // Cada premio gerado no título gera X números da sorte
                                parseInt(result.qtdTitulos) *
                                parseInt(result.data.campanha.qtdPremios) *
                                parseInt(result.data.campanha.qtdNumerosDaSortePorTitulo)
                            ),
                        qtdTotalProcessosConcluidos: 0
                    };

                    result.data.compra.vlTotalCompra = parseFloat((result.qtdTitulos * result.data.campanha.vlTitulo).toFixed(2));

                    result.data.compra = {
                        ...result.data.compra,
                        ...result.data.titulo
                    }

                    result.data.compra.keywords = global.generateKeywords(
                        result.data.compra.nome,
                        result.data.compra.cpf,
                        result.data.compra.email,
                        result.data.compra.celular
                    );

                    global.setDateTime(result.data.compra, 'dtInclusao');

                    return collectionTitulosCompras.add(result.data.compra);

                })

                .then(resultTituloCompra => {
                    result.data.compra = resultTituloCompra;

                    // Dados dos Títulos
                    result.data.titulo.qtdPremios = result.data.campanhaPremios.length;
                    result.data.titulo.qtdNumerosDaSortePorTitulo = result.data.campanha.qtdNumerosDaSortePorTitulo;
                    result.data.titulo.campanhaNome = result.data.campanha.titulo;
                    result.data.titulo.campanhaSubTitulo = result.data.campanha.subTitulo || '';
                    result.data.titulo.campanhaDetalhes = result.data.campanha.detalhes || '';
                    result.data.titulo.campanhaVlTitulo = result.data.campanha.vlTitulo;
                    result.data.titulo.campanhaQtdPremios = result.data.campanha.qtdPremios;
                    result.data.titulo.campanhaTemplate = result.data.campanha.template;
                    result.data.titulo.uidComprador = this.parm.attributes.user_uid;
                    result.data.titulo.situacao = 'aguardando-pagamento';
                    result.data.titulo.qtdNumerosGerados = 0;
                    result.data.titulo.gerado = false;

                    result.data.titulo.idTituloCompra = result.data.compra.id;
                    result.data.titulo.keywords = result.data.compra.keywords;

                    // Inicializa o controle de acompanhamento da Compra (os dados que podem ser vistos pelo cliente no front)
                    const promise = [
                        acompanhamentoTituloCompra.initAcompanhamento(result.data.compra)
                    ];

                    for (let i = 0; i < result.qtdTitulos; i++) {
                        const t = { guidTitulo: global.guid() }

                        global.setDateTime(t, 'dtInclusao');

                        promise.push(collectionTitulos.add({ ...result.data.titulo, ...t }));
                    }

                    return Promise.all(promise);
                })

                .then(resultTitulos => {
                    result.data = {
                        compra: result.data.compra,
                        titulos: resultTitulos.filter(f => { return f.guidTitulo; })
                    }

                    // Salva os títulos no acompanhamento
                    return acompanhamentoTituloCompra.setTitulos(result.data.compra, result.data.titulos);
                })

                .then(_ => {
                    // Verifica se existe um PIX disponível no PIX Storage com a mesma CHAVE e VALOR
                    // - A chave PIX está em result.compra.pixKeyCredito
                    // - O valor total está em result.data.compra.vlTotalCompra

                    const pixKey = result.data.campanha.pixKeyCredito;
                    const valor = parseInt((result.data.compra.vlTotalCompra * 100).toFixed(0));


                    // Adição concluída. Momento de gerar o pedido de pagamento...
                    return generatePedidoPagamentoCompra.call({
                        idTituloCompra: result.data.compra.id
                    });
                })

                .then(pedidoPagamentoResult => {
                    result.data.pedidoPagamento = pedidoPagamentoResult.result;

                    // Retornando só o que interessa
                    result.data = {
                        compra: { id: result.data.compra.id },
                        pedidoPagamento: result.data.pedidoPagamento
                    };

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
        name: 'generate-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.token,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    if (!request.body || !request.body.idCampanha) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
