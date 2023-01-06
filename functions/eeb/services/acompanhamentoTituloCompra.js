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
            emailEnviado: false,
            qtdTotalProcessos: qtdTotalProcessos,
            qtdTotalProcessosConcluidos: 0
        };

    global.setDateTime(toAdd, 'dtInclusao');

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

        global.setDateTime(data, 'pixData_criacao');

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

        global.setDateTime(data, 'dtPagamento');

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

        global.setDateTime(data, 'validacaoDtInicio');

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

        if (data.validacaoConcluida) global.setDateTime(data, 'validacaoDtFinal');

        return data;
    });
}


exports.initAcompanhamento = initAcompanhamento;
exports.incrementProcessosConcluidos = incrementProcessosConcluidos;
exports.setPixData = setPixData;
exports.setPago = setPago;
exports.setValidacaoEmAndamento = setValidacaoEmAndamento;
exports.incrementValidacao = incrementValidacao;
