"use strict";

const moment = require("moment-timezone");

exports.clientes = doc => {
    const endpoint = `/api/v1/cliente/${doc.id || '?'}`;
    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        idUser: doc.idUser,
        // Dados recebidos
        doc: {
            tipo: doc.cpfcnpj_type,
            cpfcnpj: doc.cpfcnpj,
            nome: doc.nome || null,
            email: doc.email || null
        },
        // Dados gerados a partir dos dados recebidos
        extrainfo: {
            cpfcnpj_formatted: doc.cpfcnpj_formatted,
            dtInclusao: moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS'),
            dtAlteracao: moment(doc.dtAlteracao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            usuario: `/api/users/v1/user/${doc.id}`
        }
    }
    return result;
};


exports.planos = doc => {
    const endpoint = `/api/v1/planos/${doc.id || '?'}`;
    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        idUser: doc.idUser,
        // Dados recebidos
        doc: {
            nome: doc.nome,
            sigla: doc.sigla,
            valorMaximo: doc.valorMaximo,
            valorMinimo: doc.valorMinimo,
            msgBoleto: doc.msgBoleto,
            ativo: doc.ativo
        },
        // Dados gerados a partir dos dados recebidos
        extrainfo: {
            dtInclusao: moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS'),
            dtAlteracao: moment(doc.dtAlteracao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            usuario: `/api/v1/usuario/${doc.idUser}`
        }
    }
    return result;
};


exports.contratos = doc => {
    const endpoint = `/api/v1/contratos/${doc.id || '?'}`;
    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        idUser: doc.idUser,
        // Dados recebidos
        doc: {
            idCliente: doc.idCliente,
            idPlano: doc.idPlano,
            periodoParcela: doc.periodoParcela,
            qtdParcelas: doc.qtdParcelas,
            valor: doc.valor,
            diaMes: doc.diaMes,
            ativo: doc.ativo
        },
        // Dados gerados a partir dos dados recebidos
        extrainfo: {
            dtAlteracao: moment(doc.dtAlteracao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            cliente: `/api/collection/v1/clientes/${doc.idCliente}`,
            plano: `/api/collection/v1/planos/${doc.idPlano}`,
            cobrancas: `/api/collection/v1/cobrancas?idCliente=${doc.idCliente}`,
            usuario: `/api/v1/usuario/${doc.idUser}`
        }
    }
    return result;
};


exports.cobrancas = doc => {
    const endpoint = `/api/v1/cobranca/${doc.id || '?'}`;
    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        uidUsuario: doc.uidUsuario,

        // Dados recebidos
        doc: {
            idCliente: doc.idCliente,
            idContrato: doc.idContrato,
            dtVencimento: doc.dtVencimento_yyyymmdd,
            liberadaParaPagamento: doc.liberadaParaPagamento,
            valor: doc.valor,
            emAtraso: doc.emAtraso,
            diasAtraso: 0
        },

        // Dados gerados a partir dos dados recebidos
        extrainfo: {
            dtInclusao: doc.dtInclusao_yyyymmdd,
            isFakeData: doc.isFakeData,
            status: doc.status
        },
        // Ações possíveis
        actions: [
            `${endpoint}/gerar-boleto`
        ],
        // extendeds...
        extend: {
            empresa: `/api/v1/empresa/${doc.idEmpresa}`,
            cliente: `/api/v1/cliente/${doc.idCliente}`,
            usuario: `/api/v1/usuario/${doc.idUser}`
        }
    }

    if (doc.idContrato !== 'avulso') {
        result.extend.contrato = `/api/v1/collection/contrato/${doc.idContrato}`;
    }

    if (doc.idPlano) {
        result.doc.idPlano = doc.idPlano;
        result.extend.plano = `/api/v1/collection/plano/${doc.idPlano}`;
    }

    if (doc.obs) { result.obs = doc.obs; }
    if (doc.msgBoleto) { result.msgBoleto = doc.msgBoleto; }

    return result;
};


exports.apiConfig = doc => {
    const endpoint = `/api/v1/api-config/${doc.id || '?'}`;

    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        idUser: doc.idUser,
        // Dados recebidos
        doc: {
            descricao: doc.descricao,
            ativo: doc.ativo
        },
        // Dados gerados a partir dos dados recebidos
        extrainfo: {
            apiKey: doc.apiKey,
            dtInclusao: moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS'),
            dtAlteracao: moment(doc.dtAlteracao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            empresa: `/api/v1/empresa/${doc.idEmpresa}`,
            usuario: `/api/v1/usuario/${doc.idUser}`
        }
    }

    return result;
};


exports.userProfile = doc => {
    const endpoint = `/api/v1/user/${doc.id || '?'}`;
    var result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        // Dados recebidos
        doc: {
            uid: doc.id,
            nome: doc.displayName || null,
            email: doc.email || null,
            celular: doc.phoneNumber || null,
            imagem: doc.photoURL || null,
            ativo: doc.ativo
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            usuario: `/api/users/v1/user/${doc.id}`
        }
    }
    if (doc.dtInclusao) {
        result.extrainfo = {
            dtInclusao: moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        }
    }
    return result;
};

exports.empresas = doc => {
    const endpoint = `/api/v1/empresas/${doc.id || '?'}`;

    var result = {
        id: doc.id,
        idUser: doc.uid,
        // Dados recebidos
        doc: {
            nome: doc.nome,
            cidade: doc.cidade || null,
            estado: doc.estado || null,
            bairro: doc.bairro || null,
            cep: doc.cep || null,

        },
        // Dados gerados a partir dos dados recebidos
        extrainfo: {
        }
    }

    if (doc.dtInclusao) {
        result.extrainfo.dtInclusao = moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS');
    }

    if (doc.dtAlteracao) {
        result.extrainfo.dtAlteracao = moment(doc.dtAlteracao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS');
    }

    return result;
};

