"use strict";

const admin = require('firebase-admin');
const global = require("../../global");

const getPath = idTituloCompra => {
    return `/titulosCompras/acompanhamento/${idTituloCompra}`;
}

async function initAcompanhamento(idTituloCompra, qtdTotalProcessos) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path),
        toAdd = {
            situacao: 'aguardando-pagamento',
            pronto: false,
            validacaoIniciada: false,
            validacaoConcluida: false,
            validacaoTotal: 0,
            validacaoTotalConcluidos: 0,
            validacaoTotalComErro: 0,
            emailEnviadoQtd: 0,
            qtdTotalProcessos: qtdTotalProcessos,
            qtdTotalProcessosConcluidos: 0,
            dtInclusao: global.nowDateTime()
        };

    return await ref.set(toAdd);
}

async function incrementProcessosConcluidos(idTituloCompra) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.qtdTotalProcessosConcluidos++;
        return data;
    });
}

async function setPixData(idTituloCompra, pixData) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.pixData = pixData;
        data.pixDataDtCriacao = global.nowDateTime();

        return data;
    });
}

async function setPago(idTituloCompra) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.situacao = 'pago';
        data.dtPagamento = global.nowDateTime();

        return data;
    });
}

async function setEmailEnviado(idTituloCompra, idTitulo, sendResult) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.emailEnviadoQtd++;
        data.emailEnviado = data.emailEnviado || {};

        data.emailEnviado[idTitulo] = {
            dtEnvio: global.nowDateTime(),
            sendResult: sendResult
        };

        return data;
    });
}

async function setValidacaoEmAndamento(idTituloCompra, qtdProcessos) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.validacaoIniciada = true;
        data.validacaoTotal = qtdProcessos;
        data.validacaoDtInicio = global.nowDateTime();

        return data;
    });
}

async function incrementValidacao(idTituloCompra, erro) {
    const
        path = getPath(idTituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.validacaoEmAndamento = true;
        data.validacaoTotalConcluidos++;
        data.validacaoConcluida = data.validacaoTotal === data.validacaoTotalConcluidos;

        if (erro) data.validacaoTotalComErro++;

        if (data.validacaoConcluida) {
            data.validacaoDtFinal = global.nowDateTime();
            data.pronto = data.validacaoTotalComErro === 0; // Só está pronto se não tem erros...

            // Quer notificar a equipe se deu merda? Coloca aqui!

        }

        return data;
    });
}

exports.initAcompanhamento = initAcompanhamento;
exports.incrementProcessosConcluidos = incrementProcessosConcluidos;
exports.setPixData = setPixData;
exports.setPago = setPago;
exports.setValidacaoEmAndamento = setValidacaoEmAndamento;
exports.incrementValidacao = incrementValidacao;
exports.setEmailEnviado = setEmailEnviado;
