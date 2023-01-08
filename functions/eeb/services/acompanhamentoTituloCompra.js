"use strict";

const admin = require('firebase-admin');
const global = require("../../global");

const getPath = tituloCompra => {
    return `/titulosCompras/${tituloCompra.idCampanha}/${tituloCompra.uidComprador}/${tituloCompra.id}`;
}

// O acompanhamento isola os dados que podem ser vistos pelos clientes no front
async function initAcompanhamento(tituloCompra) {
    const
        path = getPath(tituloCompra),
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
            qtdTotalProcessos: tituloCompra.qtdTotalProcessos,
            qtdTotalProcessosConcluidos: 0,
            qtdTitulos: tituloCompra.qtdTitulosCompra,
            vlTotalCompra: tituloCompra.vlTotalCompra,
            dtInclusao: global.nowDateTime(),
            guidCompra: tituloCompra.guidCompra,

            campanhaId: tituloCompra.idCampanha,
            campanhaNome: tituloCompra.campanhaNome,
            campanhaQtdPremios: tituloCompra.campanhaQtdPremios,

            compradorNome: tituloCompra.nome,
            compradorCpf: tituloCompra.cpf_formated,
            compradorCpfHide: tituloCompra.cpf_hide,
            compradorCelular: tituloCompra.celular_formated,
            compradorEmail: tituloCompra.email,
            compradorEmailHide: tituloCompra.email_hide
        };

    return await ref.set(toAdd);
}

async function incrementProcessosConcluidos(tituloCompra) {
    const
        path = getPath(tituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.qtdTotalProcessosConcluidos++;
        return data;
    });
}

async function setPixData(tituloCompra, pixData) {
    const
        path = getPath(tituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.pixData = {
            EMV: pixData.QRCode.EMV,
            Imagem: pixData.QRCode.Imagem,
            additionalInfo: pixData.additionalInfo,
            createdAt: pixData.createdAt,
            merchantCity: pixData.merchantCity,
            receiverKey: pixData.receiverKey,
            txId: pixData.txId,
            value: pixData.value
        };
        data.pixDataDtCriacao = global.nowDateTime();

        return data;
    });
}

async function setPago(tituloCompra) {
    const
        path = getPath(tituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.situacao = 'pago';
        data.dtPagamento = global.nowDateTime();

        return data;
    });
}

async function setEmailEnviado(tituloCompra, idTitulo, sendResult) {
    const
        path = getPath(tituloCompra),
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

async function setValidacaoEmAndamento(tituloCompra, qtdProcessos) {
    const
        path = getPath(tituloCompra),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.validacaoIniciada = true;
        data.validacaoTotal = qtdProcessos;
        data.validacaoDtInicio = global.nowDateTime();

        return data;
    });
}

async function incrementValidacao(tituloCompra, erro) {
    const
        path = getPath(tituloCompra),
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
