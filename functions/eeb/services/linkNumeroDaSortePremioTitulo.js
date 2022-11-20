"use strict";

const admin = require('firebase-admin');
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

// Receber no parametro um guidTitulo e idInfluencer (obrigatórios)
// Pesquisar e criar o título se não existir
// Cada chamada do generateTitulo gera um número da sorte e grava no título
// Se são 2 números, esta rotina deve ser chamada 2 vezes
// Esta rotina sofre retentativa automática. Se houver colisão com outra geração, não tentar novamente na rotinas
// Lembre-se que esta rotina deve ser chamada uma vez para cada número da sorte de cada premio de cada titulos
// Se chamar mais do que a quantidade de números da sorte do premio, ignora
// Todo título tem o mesmo guidTitulo para todos os seus premios

const linkNumeroDaSorteSchema = _ => {
    const schema = Joi.object({
        idPremioTitulo: Joi.string().token().min(18).max(22).required()
    });

    return schema;
}

const findLote = path => {
    return new Promise((resolve, reject) => {
        const ref = admin.database().ref(`${path}/lotes`);
        const query = ref.orderByChild('qtdDisponiveis').limitToLast(1);

        console.info('Search:', path);

        return query.on('value', data => {
            data = data.val();

            if (!data || typeof data !== 'object') {
                return reject(new Error(`Não existe nenhum lote de números gerados para o premio [${path}]`));
            }

            return resolve(Object.keys(data)[0]);
        })
    })
}

const getNumero = (path, idTitulo) => {
    return new Promise((resolve, reject) => {
        const result = {};

        return findLote(path)

            .then(lote => {
                result.idLote = lote;
                result.pathLote = `${path}/lotes/${lote}`;

                return admin.database().ref(result.pathLote).transaction(data => {
                    if (data.qtdDisponiveis && data.qtdDisponiveis > 0) {
                        data.qtdDisponiveis--;
                        data.qtdUtilizados++;

                        const pos = data.numeros.findIndex(f => { return f.t === 0; });

                        if (pos >= 0) {
                            result.lote = data.codigo;
                            result.numero = data.codigo.toString().padStart(2, '0') + data.numeros[pos].n.toString().padStart(3, '0');
                            data.numeros[pos].t = idTitulo;
                        }
                    }

                    result.qtdDisponiveis = data.qtdDisponiveis;
                    result.qtdUtilizados = data.qtdUtilizados;

                    return data;
                });
            })

            .then(transactionResult => {
                if (!transactionResult.committed) {
                    throw new Error('Transaction error...');
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const updatePremioTitulo = async (idPremioTitulo, numeroDaSorte) => {
    const premioTituloRef = admin.firestore().collection("titulosPremios").doc(idPremioTitulo);

    try {
        await admin.firestore().runTransaction(async t => {
            const doc = await t.get(premioTituloRef);

            const numerosDaSorte = doc.data().numerosDaSorte || [];
            const linksNumerosDaSorte = doc.data().linksNumerosDaSorte || [];

            numerosDaSorte.push(numeroDaSorte.numero);
            linksNumerosDaSorte.push(numeroDaSorte);

            await t.update(premioTituloRef, {
                numerosDaSorte: numerosDaSorte,
                linksNumerosDaSorte: linksNumerosDaSorte
            });

            return true;
        });
    } catch (e) {
        console.error(e);

        return false;
    }
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {

        const result = {
            success: true,
            host: this.parm.host,
            jaGerado: false,
            data: {}
        };

        return new Promise((resolve, reject) => {

            return linkNumeroDaSorteSchema().validateAsync(this.parm.data)
                .then(dataResult => {
                    result.data = dataResult;

                    return collectionTitulosPremios.getDoc(result.data.idPremioTitulo);
                })

                .then(resultPremioTitulo => {
                    result.data.premioTitulo = resultPremioTitulo;

                    if (result.data.premioTitulo.numerosDaSorte.length >= result.data.premioTitulo.qtdNumerosDaSortePorTitulo) {
                        result.jaGerado = true;
                        return true;
                    }

                    result.idCampanha = result.data.premioTitulo.idCampanha;
                    result.idPremio = result.data.premioTitulo.idPremio;
                    result.idTitulo = result.data.premioTitulo.idTitulo;
                    result.path = `/numerosDaSorte/${result.idCampanha}/${result.idPremio}`;

                    return getNumero(result.path, result.idTitulo);
                })

                .then(getNumeroResult => {
                    if (result.jaGerado) return true;

                    result.numero = getNumeroResult;

                    return updatePremioTitulo(result.data.idPremioTitulo, result.numero);
                })

                .then(_ => {
                    delete result.premio;

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

const call = (idPremioTitulo, request, response) => {

    const service = new Service(request, response, {
        name: 'link-numero-da-sorte-premio-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        noAuth: true,
        ordered: true,
        orderingKey: idPremioTitulo,
        data: {
            idPremioTitulo: idPremioTitulo
        },
        attributes: {
            idEmpresa: 'all'
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const idPremioTitulo = request.body.idPremioTitulo || null;

    const host = global.getHost(request);

    if (!idPremioTitulo || host !== 'localhost') {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idPremioTitulo, request, response);
}
