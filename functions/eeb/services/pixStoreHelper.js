"use strict";

const admin = require('firebase-admin');
const global = require('../../global');

const getPathConfig = pixKey => {
    return `/pixStore/${pixKey}/config`;
}

const getPathQtd = (pixKey, valor) => {
    return `/pixStore/${pixKey}/qtd/${valor.toString()}`;
}

const incrementPixKeyValue = (pixKey, valor) => {
    return new Promise((resolve, reject) => {
        const path = getPathQtd(pixKey, valor);
        const ref = admin.database().ref(path);

        return ref.transaction(data => {
            data = data || {};

            data.qtdAtual = data.qtdAtual || 0;

            data.qtdAtual++;
            data.dtLastIncrementUpdate = global.getToday();

            return data;
        }).then(transactionResult => {
            if (!transactionResult.committed) throw new Error('incrementPixKeyValue Transaction error...');

            return resolve();
        }).catch(e => {
            console.error(e);

            return reject(e);
        })

    })
}

const decrementPixKeyValue = (pixKey, valor, reset) => {
    reset = typeof reset === 'boolean' ? reset : false;

    return new Promise((resolve, reject) => {
        const path = getPathQtd(pixKey, valor);
        const ref = admin.database().ref(path);

        return ref.transaction(data => {
            data = data || {};

            data.qtdAtual = data.qtdAtual || 0;

            if (data.qtdAtual > 0) {
                reset ? data.qtdAtual = 0 : data.qtdAtual--;
            }

            data.dtLastDecrementUpdate = global.getToday();

            return data;
        }).then(transactionResult => {
            if (!transactionResult.committed) throw new Error('decrementPixKeyValue Transaction error...');

            return resolve(null);
        }).catch(e => {
            console.error(e);

            return reject(e);
        })

    })
}

async function getPixKeyConfig(pixKey) {
    const
        path = getPathConfig(pixKey),
        query = admin.database().ref(path),
        pixStoreConfig = await query.once("value");

    return pixStoreConfig.val() || null;
}

async function getPixKeyQtd(pixKey, valor) {
    const
        path = getPathQtd(pixKey, valor),
        query = admin.database().ref(path + '/qtdAtual'),
        qtd = await query.once("value");

    return qtd.val() || -1;
}

const toSeconds = time => {
    return parseFloat(parseFloat(time[0] + '.' + time[1]).toFixed(2));
}

async function findNotUsedPix(pixKey, valor, compra) {
    /*
    Este metodo faz o seguinte:
    - Abre uma transação localizando o próximo PIX que ainda não foi utilizado com a mesma chave e valor
    - Passa o PIX para utilizado, informando os dados da compra
    */

    let result = null,
        doc = null;

    const query = admin.firestore().collection("cartosPixPreGenerated")
        .where('receiverKey', '==', pixKey)
        .where('value', '==', valor)
        .where('utilizado', '==', false)
        .orderBy('dtInclusao_js')
        .limit(1);

    return admin.firestore().runTransaction(transaction => {

        return transaction.get(query)
            .then(docs => {

                if (docs.size === 0) { // Not found
                    return decrementPixKeyValue(pixKey, valor, true);
                }

                const updateData = { utilizado: true };

                docs.forEach(d => {
                    doc = d;

                    result = Object.assign(doc.data(), { id: d.id });

                    global.setDateTime(updateData, 'dtUtilizacao');

                    if (compra) {
                        updateData.idTituloCompra = compra.id;
                        updateData.idCampanha = compra.idCampanha;
                        updateData.idInfluencer = compra.idInfluencer;
                        updateData.comprador_email = compra.email;
                        updateData.comprador_uid = compra.uidComprador;
                        updateData.comprador_celular = compra.celular;
                        updateData.comprador_celular_formated = compra.celular_formated;
                        updateData.comprador_nome = compra.nome;
                        updateData.comprador_cpf = compra.cpf;
                        updateData.comprador_cpf_formated = compra.cpf_formated;
                        updateData.dtUtilizacao = global.getToday();
                    }
                });

                transaction.update(doc.ref, updateData);

                result = {
                    ...result,
                    ...updateData
                };

                return result;

            })

            .then(updateResult => {
                if (!updateResult) return null;

                if (result) {
                    // Decrementa o total de Documentos disponíveis para o PIX/Valor
                    return decrementPixKeyValue(pixKey, valor);
                } else {
                    return null;
                }
            })

            .then(_ => {
                return result;
            })

            .catch(e => {
                console.error(e.message);

                return null;
            })
    })

}

exports.getPathConfig = getPathConfig;
exports.getPathQtd = getPathQtd;
exports.incrementPixKeyValue = incrementPixKeyValue;
exports.decrementPixKeyValue = decrementPixKeyValue;
exports.getPixKeyConfig = getPixKeyConfig;
exports.getPixKeyQtd = getPixKeyQtd;
exports.toSeconds = toSeconds;
exports.findNotUsedPix = findNotUsedPix;
