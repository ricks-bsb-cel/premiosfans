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


exports.getPathConfig = getPathConfig;
exports.getPathQtd = getPathQtd;
exports.incrementPixKeyValue = incrementPixKeyValue;
exports.decrementPixKeyValue = decrementPixKeyValue;
exports.getPixKeyConfig = getPixKeyConfig;
exports.getPixKeyQtd = getPixKeyQtd;
exports.toSeconds = toSeconds;
