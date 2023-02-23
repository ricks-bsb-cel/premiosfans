"use strict";

const admin = require('firebase-admin');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const FieldValue = require('firebase-admin').firestore.FieldValue;

/*
Esta rotina roda em fila para idPremios iguais!
*/

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanha = firestoreDAL.campanhas();
const collectionCampanhaSorteioPremios = firestoreDAL.campanhasSorteiosPremios();
const collectionTitulosPremios = firestoreDAL.titulosPremios();
const collectionTitulosCompras = firestoreDAL.titulosCompras();

const checkTitulosCompra = require('./checkTitulosCompra');
const acompanhamentoTituloCompra = require('./acompanhamentoTituloCompra');

const bigQueryAddRow = require('./bigquery/bigqueryAddRow');

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
        idPremio: Joi.string().token().min(18).max(22).required(),
        idPremioTitulo: Joi.string().token().min(18).max(22).required()
    });

    return schema;
}

const findLote = path => {
    return new Promise((resolve, reject) => {
        const ref = admin.database().ref(`${path}/lotes`);
        const query = ref.orderByChild('qtdDisponiveis').limitToLast(1);

        return query.on('value', data => {
            data = data.val();

            if (!data || typeof data !== 'object') {
                return reject(new Error(`Não existe nenhum lote de números gerados para o premio [${path}]`));
            }

            if (data.qtdDisponiveis <= 0) {
                return reject(new Error(`Lotes esgotados [${path}]`));
            }

            return resolve(Object.keys(data)[0]);
        })
    })
}

const getNumero = (parm) => {

    const path = parm.path,
        idTitulo = parm.idTitulo,
        gruposLength = parm.gruposLength,
        NumerosPorGrupoLength = parm.NumerosPorGrupoLength;

    return new Promise((resolve, reject) => {
        const result = {};

        return findLote(path)

            .then(lote => {
                result.idLote = lote;
                result.pathLote = `${path}/lotes/${lote}`;

                const ref = admin.database().ref(result.pathLote);

                return ref.transaction(data => {

                    if (!data) throw new Error(`Nenhum lote localizado no path ${result.pathLote}`);

                    if (data.qtdDisponiveis && data.qtdDisponiveis > 0) {
                        data.qtdDisponiveis--;
                        data.qtdUtilizados++;

                        const pos = data.numeros.findIndex(f => {
                            return f.t === 0;
                        });

                        if (pos < 0) throw new Error('Lote esgotado. Nenhum número encontrado para ser utilizado.');

                        result.lote = data.codigo;
                        result.numero = data.codigo.toString().padStart(gruposLength, '0') + data.numeros[pos].n.toString().padStart(NumerosPorGrupoLength, '0');
                        data.numeros[pos].t = idTitulo;
                    }

                    result.qtdDisponiveis = data.qtdDisponiveis;
                    result.qtdUtilizados = data.qtdUtilizados;

                    return data;
                });
            })

            .then(transactionResult => {
                if (!transactionResult.committed) throw new Error('Transaction error...');

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const toBigQueryTablePremiosCompras = (numeroDaSorte, sorteioPremio, tituloPremio) => {
    const data = {
        idTituloPremio: tituloPremio.id,
        idPremio: tituloPremio.idPremio,
        idSorteio: tituloPremio.idSorteio,
        idTitulo: tituloPremio.idTitulo,
        idCompra: tituloPremio.idTituloCompra,
        idCampanha: tituloPremio.idCampanha,

        posPremio: sorteioPremio.pos,

        uidComprador: tituloPremio.uidComprador,

        numeroDaSorte: parseInt(numeroDaSorte.numero),

        premioDescricao: sorteioPremio.descricao,
        premioValor: parseFloat(sorteioPremio.valor.toFixed(2)),

        dtSorteio: tituloPremio.sorteioDtSorteio_yyyymmdd
    };

    // Estrutura da tabela
    return {
        "tableType": "bigQueryTablePremiosCompras",
        "datasetId": "campanha_" + tituloPremio.idCampanha,
        "tableName": "comprasPremios",
        "row": data
    };
}

const updatePremioTitulo = async (idPremioTitulo, numeroDaSorte, tituloPremio, sorteioPremio) => {
    const premioTituloRef = admin.firestore().collection("titulosPremios").doc(idPremioTitulo);

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

        // Envia os dados do prêmio para a base de dados do BigQuery
        await bigQueryAddRow.call(toBigQueryTablePremiosCompras(numeroDaSorte, sorteioPremio, tituloPremio));

        return true;
    });

}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

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

                    if (result.data.premioTitulo.numerosDaSorte && result.data.premioTitulo.numerosDaSorte.length >= result.data.premioTitulo.qtdNumerosDaSortePorTitulo) {
                        result.jaGerado = true;
                        return true;
                    }

                    result.idCampanha = result.data.premioTitulo.idCampanha;
                    result.idPremio = result.data.premioTitulo.idPremio;
                    result.idTitulo = result.data.premioTitulo.idTitulo;

                    result.path = `/numerosDaSorte/${result.idCampanha}/${result.idPremio}`;

                    // return collectionCampanha.getDoc(result.idCampanha);
                    return Promise.all([
                        collectionCampanha.getDoc(result.idCampanha),
                        collectionCampanhaSorteioPremios.getDoc(result.idPremio)
                    ])
                })

                .then(promiseResult => {
                    if (result.jaGerado) return true;

                    result.campanha = promiseResult[0];
                    result.sorteioPremio = promiseResult[1];

                    result.gruposLength = (result.campanha.qtdGrupos - 1).toString().length;
                    result.NumerosPorGrupoLength = (result.campanha.qtdNumerosPorGrupo - 1).toString().length;

                    return getNumero(result);
                })

                .then(getNumeroResult => {
                    if (result.jaGerado) return true;

                    result.numero = getNumeroResult;

                    return updatePremioTitulo(
                        result.data.idPremioTitulo,
                        result.numero,
                        result.data.premioTitulo,
                        result.sorteioPremio
                    );
                })

                .then(_ => {
                    if (result.jaGerado) return true;

                    // Atualização de Contadores
                    return Promise.all([
                        admin.firestore().collection('titulos').doc(result.data.premioTitulo.idTitulo).set({ qtdNumerosGerados: FieldValue.increment(1) }, { merge: true }),
                        admin.firestore().collection('titulosCompras').doc(result.data.premioTitulo.idTituloCompra).set({
                            qtdNumerosGerados: FieldValue.increment(1),
                            qtdTotalProcessosConcluidos: FieldValue.increment(1)
                        }, { merge: true }),
                        acompanhamentoTituloCompra.incrementProcessosConcluidos(result.data.premioTitulo)
                    ])
                })

                .then(_ => {
                    if (result.jaGerado) return true;

                    // Verifica se tudo já foi gerado
                    return collectionTitulosCompras.getDoc(result.data.premioTitulo.idTituloCompra);
                })

                .then(tituloCompra => {
                    if (result.jaGerado) return true;

                    // Tudo foi gerado. Solicita a validação da compra.
                    if (tituloCompra.qtdTotalProcessos === tituloCompra.qtdTotalProcessosConcluidos) {
                        return checkTitulosCompra.call({ idTituloCompra: result.data.premioTitulo.idTituloCompra });
                    } else {
                        return null;
                    }
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

const call = (idPremio, idPremioTitulo, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    // O orderingKey é o idPremio.
    // Caso mais do que uma solicitação de link do número tenha o mesmo
    // idPremio, o pedido será enfileirado no PubSub (e não executado em paralelo)

    const service = new Service(request, response, {
        name: 'link-numero-da-sorte-premio-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        ordered: true,
        orderingKey: idPremio,
        data: {
            idPremio: idPremio,
            idPremioTitulo: idPremioTitulo
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const idPremio = request.body.idPremio || null;
    const idPremioTitulo = request.body.idPremioTitulo || null;

    if (!idPremio || !idPremioTitulo) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idPremio, idPremioTitulo, request, response);
}
