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

const decrementPixKeyValue = (pixKey, valor) => {
    return new Promise((resolve, reject) => {
        const path = getPathQtd(pixKey, valor);
        const ref = admin.database().ref(path);

        return ref.transaction(data => {
            data = data || {};

            data.qtdAtual = data.qtdAtual || 0;

            if (data.qtdAtual > 0) data.qtdAtual--;

            data.dtLastDecrementUpdate = global.getToday();

            return data;
        }).then(transactionResult => {
            if (!transactionResult.committed) throw new Error('decrementPixKeyValue Transaction error...');

            return resolve();
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

    let id = null,
        result = null;

    const query = admin.firestore().collection("cartosPixPreGenerated")
        .where('receiverKey', '==', pixKey)
        .where('value', '==', valor)
        .where('utilizado', '==', false)
        .orderBy('dtInclusao_js')
        .limit(1);

    return admin.firestore().runTransaction(transaction => {

        return transaction.get(query)
            .then(docs => {

                if (docs.size === 0) { // not found
                    console.info('not found');
                    return result;
                }

                docs.forEach(d => {
                    id = d.id;

                    transaction.update(d.ref, {
                        utilizado: true,
                        idCampanha: compra.idCampanha,
                        idInfluencer: compra.idInfluencer,
                        comprador_email: compra.email,
                        comprador_uid: compra.uidComprador,
                        comprador_celular: compra.celular

                    })
                })

                return admin.firestore().collection("cartosPixPreGenerated").doc(id).get();
            })

            .then(docUpdated => {
                if (docUpdated) {
                    result = docUpdated.data();
                    result.id = id;
                }

                if (result) {
                    return decrementPixKeyValue(pixKey, valor);
                } else {
                    return null;
                }
            })

            .then(_ => {
                return result;
            })

            .catch(e => {
                console.error(e);

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
