"use strict";

const admin = require('firebase-admin');
const global = require("../../global");

const getPathByDoc = doc => {
    if (!doc.idCampanha || !doc.uidComprador) throw new Error(`Erro criando path em acompanhamentoTituloCompra. O documento não tem idCampanha e/ou uidComprador`);

    const
        idCampanha = doc.idCampanha,
        uidComprador = doc.uidComprador;

    let idTituloCompra;

    if (doc.situacao && doc.vlTotalCompra && doc.qtdPremios) {
        // O documento é da coleção titulosCompra
        idTituloCompra = doc.id;
    } else {
        if (!doc.idTituloCompra) throw new Error(`Erro criando path em acompanhamentoTituloCompra. O documento não tem idTituloCompra`);
        idTituloCompra = doc.idTituloCompra;
    }

    return `/titulosCompras/${idCampanha}/${uidComprador}/${idTituloCompra}`;
}

// O acompanhamento isola os dados que podem ser vistos pelos clientes no front
async function initAcompanhamento(tituloCompra) {
    const
        path = getPathByDoc(tituloCompra),
        ref = admin.database().ref(path),
        toAdd = {
            id: tituloCompra.id,
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
            msg: 'Preparando Pagamento',

            compradorNome: tituloCompra.nome,
            compradorCpf: tituloCompra.cpf_formated,
            compradorCpfHide: tituloCompra.cpf_hide,
            compradorCelular: tituloCompra.celular_formated,
            compradorEmail: tituloCompra.email,
            compradorEmailHide: tituloCompra.email_hide
        };

    await ref.set(toAdd);

    return path;
}

// O doc deve ter idCampanha, uidComprador e idTituloCompra ou id
async function incrementProcessosConcluidos(doc) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path),
        msg = 'Gerando seus Números da Sorte'

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.qtdTotalProcessosConcluidos++;

        if (data.msg !== msg) data.msg = msg;

        return data;
    });
}

async function setPixData(doc, pixData) {
    const
        path = getPathByDoc(doc),
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
    }).then(update => {
        if (!update.committed) {
            console.info(`Erro atualizando RTDB [${path}]`);
        }

        return update.snapshot || null;
    })
}

const get = doc => {
    return new Promise(resolve => {
        const path = getPathByDoc(doc);
        const ref = admin.database().ref(path);

        return ref.on('value', data => {
            return resolve(data.val() || null)
        })
    })

}

async function setPago(doc) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.situacao = 'pago';
        data.dtPagamento = global.nowDateTime();
        data.msg = 'Verificando pagamento';

        return data;
    });
}

async function setEmailEnviado(doc, idTitulo, sendResult) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.emailEnviadoQtd++;
        data.emailEnviado = data.emailEnviado || {};
        data.msg = 'Enviando eMail';

        data.emailEnviado[idTitulo] = {
            dtEnvio: global.nowDateTime(),
            sendResult: sendResult
        };

        return data;
    });
}

async function setValidacaoEmAndamento(doc, qtdProcessos) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path),
        msg = 'Validando Certificados dos Títulos'

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.validacaoIniciada = true;
        data.validacaoTotal = qtdProcessos;
        data.validacaoDtInicio = global.nowDateTime();

        if (data.msg !== msg) data.msg = msg;

        return data;
    });
}

async function incrementValidacao(doc, erro) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path),
        msg = 'Validando Certificados dos Títulos'

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.validacaoEmAndamento = true;
        data.validacaoTotalConcluidos++;
        data.validacaoConcluida = data.validacaoTotal === data.validacaoTotalConcluidos;

        if (data.msg !== msg) data.msg = msg;

        if (erro) data.validacaoTotalComErro++;

        if (data.validacaoConcluida) {
            data.validacaoDtFinal = global.nowDateTime();
            data.pronto = data.validacaoTotalComErro === 0; // Só está pronto se não tem erros...

            // Quer notificar a equipe se deu merda? Coloca aqui!

        }

        return data;
    });
}

async function setTitulos(doc, titulos) {
    const
        path = getPathByDoc(doc),
        ref = admin.database().ref(path);

    return ref.transaction(data => {
        if (!data || typeof data !== 'object') return null;

        data.titulos = data.titulos || [];

        titulos.forEach(t => {
            if (t.id && t.qtdPremios) {
                data.titulos.push({
                    id: t.id,
                    qtdPremios: t.qtdPremios,
                    qtdNumeroDaSorte: t.qtdNumerosDaSortePorTitulo,
                    link: `/titulo/${doc.idCampanha}/${t.id}`
                })
            }
        })

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
exports.setTitulos = setTitulos;
exports.get = get;
