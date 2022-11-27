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

const collectionCampanha = firestoreDAL.campanhas();
const collectionCampanhaInfluencers = firestoreDAL.campanhasInfluencers();
const collectionCampanhaSorteios = firestoreDAL.campanhasSorteios();
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

const collectionTitulo = firestoreDAL.titulos();
const collectionTituloCompra = firestoreDAL.titulosCompras();
const collectionTitulosPremios = firestoreDAL.titulosPremios();

const tituloCompra = _ => {
    const schema = Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required()
    });

    return schema;
}

const checkNumeroTituloPremio = (idCampanha, idTitulo, idPremio, idTituloPremio, numero) => {
    return new Promise((resolve, reject) => {
        return collectionTitulosPremios.get({
            filter: [
                { field: "idCampanha", condition: "==", value: idCampanha },
                { field: "idPremio", condition: "==", value: idPremio },
                { field: "numerosDaSorte", condition: "array-contains", value: numero }
            ]
        })
            .then(resultTitulosPremios => {

                resultTitulosPremios = resultTitulosPremios.filter(f => {
                    return f.id !== idTituloPremio;
                });

                return resolve({
                    error: resultTitulosPremios.length > 0,
                    idPremio: idPremio,
                    idTitulo: idTitulo,
                    idTituloPremio: idTituloPremio,
                    numero: numero,
                    conflitos: resultTitulosPremios
                })
            })

            .catch(e => {
                console.error(e);

                return reject(e);
            })
    })
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
                data: {
                    idTituloCompra: 0,
                    errors: [],
                    qtdErrors: 0
                }
            };

            const addError = (collection, detalhes) => {
                result.data.errors.push({
                    collection: collection,
                    detalhes: detalhes,
                    detalhes_html: detalhes.replaceAll('[', '<strong class="monospace">').replaceAll(']', '</strong>')
                });

                result.data.qtdErrors = result.data.errors.length;
            }

            return tituloCompra().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data.idTituloCompra = dataResult.idTituloCompra;

                    return collectionTituloCompra.set(result.data.idTituloCompra, {
                        errorsExists: null,
                        errorsQtd: null,
                        errors: null,
                        errosDtCheck: null,
                        errosDtCheck_js: null,
                        errosDtCheck_js_desc: null,
                        errosDtCheck_timestamp: null
                    }, true);
                })

                .then(_ => {

                    // Carrega os dados
                    return Promise.all([
                        collectionTituloCompra.getDoc(result.data.idTituloCompra),
                        collectionTitulo.get({ filter: [{ field: "idTituloCompra", condition: "==", value: result.data.idTituloCompra }] }),
                        collectionTitulosPremios.get({ filter: [{ field: "idTituloCompra", condition: "==", value: result.data.idTituloCompra }] })
                    ]);
                })

                .then(promiseResult => {
                    result.data.tituloCompra = promiseResult[0]; // A compra que está sendo verificada
                    result.data.titulos = promiseResult[1]; // Os títulos adquiridos na compra
                    result.data.titulosPremios = promiseResult[2]; // Os premios gerados para a compra

                    // Compra está paga?
                    if (result.data.tituloCompra.situacao !== 'pago') {
                        addError(`tituloCompra`, `A compra não está paga`);
                        return false;
                    }

                    // Quantidade de títulos gerados coincide com o pedido na compra?
                    if (result.data.tituloCompra.qtdTitulosCompra !== result.data.titulos.length) {
                        addError(`titulos`, `A quantidade de títulos solicitada na compra [${result.data.tituloCompra.qtdTitulosCompra}] não coincide com o total de títulos [${result.data.titulos.length}]`)
                    }

                    return Promise.all([
                        collectionCampanha.getDoc(result.data.tituloCompra.idCampanha),
                        collectionCampanhaInfluencers.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.tituloCompra.idCampanha }] }),
                        collectionCampanhaSorteios.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.tituloCompra.idCampanha }] }),
                        collectionCampanhasSorteiosPremios.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.tituloCompra.idCampanha }] })
                    ]);
                })

                .then(promiseResult => {

                    if (!promiseResult) return [];

                    result.data.campanha = promiseResult[0]; // Campanha
                    result.data.campanhasInfluencers = promiseResult[1]; // Influencers da Campanha
                    result.data.sorteios = promiseResult[2]; // Sorteios da Campanha
                    result.data.premios = promiseResult[3]; // Premios da Campanha

                    result.data.qtdTitulos = result.data.titulos.length; // Total de títulos da compra
                    result.data.qtdPremios = result.data.titulosPremios.length; // Total de premios da compra
                    result.data.situacao = result.data.tituloCompra.situacao;
                    result.data.dtInclusao = result.data.tituloCompra.dtInclusao;
                    result.data.dtPagamento = result.data.tituloCompra.dtPagamento;

                    result.data.qtdPremiosCampanha = result.data.premios.length;

                    // Cada título gerado deve ter a mesma quantidade de premios da campanha

                    // Quantidade premios informada na campanha é igual a guantidade de premios?
                    if (result.data.campanha.qtdPremios !== result.data.qtdPremiosCampanha) {
                        addError(`campanha`, `A quantidade de premios informado na campanha [${result.data.campanha.qtdPremios}] não coincide com a quantidade de prêmios existente [${qtdPremios}]`);
                    }

                    // Verifica cada título
                    result.data.titulos.forEach(t => {
                        // Total de premios lançado para o título
                        const qtdPremiosTitulo = result.data.titulosPremios.filter(f => { return f.idTitulo === t.id; }).length;

                        // A quantidade de premios informada no título é igual a quantidade lançada na campanha?
                        if (t.campanhaQtdPremios !== result.data.qtdPremiosCampanha) {
                            addError(`titulos`, `A quantidade de premios [${t.campanhaQtdPremios}] do idTitulo [${t.id}] não coincide com a quantidade de premios informado na campanha [${qtdPremios}]`)
                        }

                        // A quantidade de premios informada no título é igual ao total de premios?
                        if (t.campanhaQtdPremios !== qtdPremiosTitulo) {
                            addError(`titulos`, `A quantidade de premios [${t.campanhaQtdPremios}] do idTitulo [${t.id}] não coincide com a quantidade de premios informado no título [${qtdPremiosTitulo}]`)
                        }

                        // A quantiade de premios no título é igual a quantidade de premios da campanha?
                        if (qtdPremiosTitulo !== result.data.qtdPremiosCampanha) {
                            addError(`titulos`, `A total de premios [${qtdPremiosTitulo}] do título [${t.id}] não coincide com o total de premios da campanha [${result.data.qtdPremiosCampanha}]`)
                        }

                    })

                    const promiseCheckNumeros = [];

                    result.data.titulosPremios.forEach(p => {
                        // Quantidade de números da sorte do premio do título tem que coincidir com o informado na campanha
                        if (p.numerosDaSorte.length !== result.data.campanha.qtdNumerosDaSortePorTitulo) {
                            addError(`titulosPremios`, `A quantidade de números da sorte [${p.numerosDaSorte.length}] do idTitulo [${p.idTitulo}], idPremio [${p.idPremio}], idPremioTitulo [${p.id}] não coincide com a quantidade solicitada na campanha [${result.data.campanha.qtdNumerosDaSortePorTitulo}]`);
                        }

                        p.numerosDaSorte.forEach(n => {
                            promiseCheckNumeros.push(checkNumeroTituloPremio(
                                p.idCampanha,
                                p.idTitulo,
                                p.idPremio,
                                p.id,
                                n
                            ))
                        })
                    })

                    return Promise.all(promiseCheckNumeros);
                })

                .then(resultCheckNumeros => {

                    result.data.resultCheckNumeros = resultCheckNumeros.filter(f => {
                        return f.error;
                    });

                    result.data.resultCheckNumeros.forEach(r => {
                        r.conflitos.forEach(c => {
                            if (result.data.idTituloCompra === c.idTituloCompra) {
                                addError(`titulosPremios`, `Conflito no número da sorte [${r.numero}] entre o 
                                idTitulo/idTituloPremio [${r.idTitulo}/${r.idTituloPremio}] e
                                idTitulo/idTituloPremio [${c.idTitulo}/${c.id}] 
                                da mesma compra.`);
                            } else {
                                addError(`titulosPremios`, `Conflito no número da sorte [${r.numero}] entre o 
                                idTitulo/idTituloPremio [${r.idTitulo}/${r.idTituloPremio}] e
                                idTitulo/idTituloPremio [${c.idTitulo}/${c.id}] 
                                do idTituloCompra [${c.idTituloCompra}].`);
                            }
                        })
                    })

                    // Salva as estatísticas de erro no titulo Compra
                    const saveError = {
                        errorsExists: result.data.qtdErrors > 0,
                        errorsQtd: result.data.qtdErrors,
                        errors: result.data.errors
                    };

                    global.setDateTime(saveError, 'errosDtCheck');
                    global.setDateTime(saveError, 'dtFinalGeracao');

                    return collectionTituloCompra.set(result.data.idTituloCompra, saveError, true);
                })

                .then(_ => {

                    // Gera Estatísticas do Título

                    // Simplifica o resultado
                    delete result.data.tituloCompra;
                    delete result.data.titulos;
                    delete result.data.titulosPremios;

                    delete result.data.campanha;
                    delete result.data.campanhasInfluencers;
                    delete result.data.sorteios;
                    delete result.data.premios;

                    global.setDateTime(result.data, 'dtOperacao');

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

    const parm = {
        name: 'check-titulo-compra',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    }

    if (data.delay) {
        parm.delay = data.delay;
        delete data.delay;
    }

    const service = new Service(request, response, parm);

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