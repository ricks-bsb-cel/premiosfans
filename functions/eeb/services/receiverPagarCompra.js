"use strict";

const helper = require('../eventBusServiceHelper');

const firestoreDAL = require('../../api/firestoreDAL');
const collectionCartosPix = firestoreDAL.cartosPix();
const collectionCartosPixPago = firestoreDAL.cartosPixPago();
const collectionTitulosCompras = firestoreDAL.titulosCompras();

const pagarCompra = require('./pagarCompra');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js

Disparado quando um webhook de pagamento de pix é recebido
Os parametros são no formato do webhook
Retransmite o recebido para o evento pagarCompra

Este evento é disparado em uma subscrição do webhook, em
https://console.cloud.google.com/cloudpubsub/topic/detail/eeb-webhook?authuser=0&project=premios-fans
que, além de dispara o evento que armazena webhooks (o /v1/whr/:source/:type?) também dispara este.

Outros eventos que devem acontecer no momento do pagamento do PIX são disparados no mesmo local
*/

async function conciliacao(payload) {
    if (!payload || !payload.transactionData) throw new Error(`Invalid transaction`);

    const txId = payload.transactionData.txId || null;

    // txId não localizado na transação
    if (!txId) throw new Error(`Invalid txId`);

    // Localiza o Pix de solicitação de pagamento pelo txId
    const collectionCartosPixResult = await collectionCartosPix.get({ filter: { txId: txId } });

    if (!collectionCartosPixResult.length) throw new Error(`Não foi encontrado nenhum cartosPix com o txId ${txId}`);
    if (!collectionCartosPixResult.length > 1) throw new Error(`Foram encontrados mais do que um cartosPix com o txId ${txId}`);

    // O pix tem os dados da compra
    const cartosPix = collectionCartosPixResult[0];
    const idTituloCompra = cartosPix.idTituloCompra;
    const transactionId = payload.transactionId;

    // Verifica no cartosPixPago se o Pagamento já foi processado. Se exitir, já foi.
    const cartosPixPago = await collectionCartosPixPago.getDoc(transactionId, false);

    if (cartosPixPago) throw new Error(`A transação PIX transactionId ${transactionId} já foi processada`);

    // Localiza a Compra (se não localizar, exception...)
    const tituloCompra = await collectionTitulosCompras.getDoc(idTituloCompra);

    // Registra o pagamento do pix em CartosPixPago (no futuro, se já existir, rejeita a transação)
    await collectionCartosPixPago.set(transactionId, payload);

    // Atualiza o cartosPix com os dados do pagamento
    const updateCartosPix = {
        cartosPixPago_updatedAt: payload.updatedAt,
        cartosPixPago_createdAt: payload.createdAt,
        cartosPixPago_id: payload.transactionId,
        cartosPixPago_accountId: payload.accountId,
        cartosPixPago_amount: parseFloat(parseFloat(payload.amount / 100).toFixed(2))
    };

    Object.keys(payload.transactionData).forEach(k => {
        if (typeof payload.transactionData[k] !== 'object') updateCartosPix[`cartosPixPago_${k}`] = payload.transactionData[k];
    })

    await collectionCartosPix.merge(cartosPix.id, updateCartosPix);

    // Dispara o evento de pagamento, que dispara o de verificação, o de email, etc...
    await pagarCompra.call({ idTituloCompra: tituloCompra.id });

    return {
        success: true
        // pixPago: payload,
        // cartosPix: cartosPix,
        // tituloCompra: tituloCompra
    };
}

const pubSubReceiver = (request, response) => {

    if (!request.body || !request.body.message) return response.status(500).json({ error: "Invalid payload" });

    const payload = helper.base64ToJson(request.body.message.data) || null;
    const transaction = payload && payload.data ? payload.data.data || null : null;

    return conciliacao(transaction)
        .then(conciliacaoResult => {
            console.info(JSON.stringify(conciliacaoResult));

            return response.status(200).end();
        })
        .catch(e => {
            console.error(e);

            return response.status(500).end();
        })


}

exports.pubSubReceiver = pubSubReceiver;
