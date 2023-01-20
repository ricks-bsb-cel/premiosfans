"use strict";

const admin = require('firebase-admin');

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');
const global = require('../../global');

/*
o Pré-Generate PIX gera um PIX e o deixa pronto para uso em uma compra futura.
Os PIXs pre gerados são armazenados na colection cartosPixPreGenerated, e não estão vinculados à nenhuma compra.
*/

const userCredentials = require('./cartos/cartosGetUserCredential');
const cartosHttpRequest = require('./cartos/cartosHttpRequests');

const firestoreDAL = require('../../api/firestoreDAL');
const collectionCartosPixPreGenerated = firestoreDAL.cartosPixPreGenerated();

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().token().min(11).required().required(),
        accountId: Joi.string().length(36).required(),
        key: Joi.string().required(),
        valor: Joi.number().min(1).max(999999).required(),
        merchantCity: Joi.string().max(32).required(),
        additionalInfo: Joi.string().max(37).required()
    });

    return schema;
}

const toSeconds = time => {
    return parseFloat(parseFloat(time[0] + '.' + time[1]).toFixed(2));
}

const incrementCounter = (pixKey, valor) => {
    return new Promise((resolve, reject) => {
        const path = `/pixStore/${pixKey}/qtd/${valor}`;
        const ref = admin.database().ref(path);

        return ref.transaction(data => {
            data = data || {};

            data.qtdAtual = data.qtdAtual || 0;

            data.qtdAtual++;
            data.dtUltimaAtualizacao = global.getToday();

            return data;
        }).then(transactionResult => {
            if (!transactionResult.committed) throw new Error('Transaction error...');

            return resolve();
        }).catch(e => {
            console.error(e);

            return reject(e);
        })

    })
}

async function pixStoreGenerate(parm) {
    const pixData = {
        cpf: parm.cpf,
        accountId: parm.accountId,
        receiverKey: parm.key,

        type: 'STATIC',
        merchantCity: parm.merchantCity,
        value: parm.valor,
        additionalInfo: parm.additionalInfo
    };

    let result = {
        utilizado: false,
        idCampanha: null,
        idInfluencer: null,
        idTituloCompra: null,
        comprador_uid: null,
        comprador_cpf: null,
        comprador_nome: null,
        comprador_celular: null,
        comprador_email: null,
    };

    const callStart = process.hrtime();

    const credential = await userCredentials.getCredential(parm.cpf, parm.accountId);

    result.elapsedTimeGetCredential = toSeconds(process.hrtime(callStart));

    const
        callPix = process.hrtime(),
        pix = await cartosHttpRequest.generatePix(pixData, credential.token);

    result.elapsedTimePixRequest = toSeconds(process.hrtime(callPix));
    result.elapsedTimeGenerate = toSeconds(process.hrtime(callStart));

    result = {
        ...pixData,
        ...pix,
        ...result
    };

    // Salva o PIX no cartosPixPreGenerated
    result = await collectionCartosPixPreGenerated.add(result);

    // Atualiza o contador
    await incrementCounter(parm.key, parm.valor);

    return result;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return pixStoreGenerate(result.parm);
                })

                .then(pixStoreGenerateResult => {
                    result.pix = pixStoreGenerateResult;

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

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    /*
    A orderingKey é o CPF, pois ele é utilizado na autenticação da Cartos
    Se for o mesmo CPF mas contas diferentes, o melhor é que as contas não fiquem mudando de um registro para outro
    pois isso atrasa o processamento, pois a rotina tem que trocar o token na Cartos antes de executar a geração do PIX
    */

    if (!data || !data.cpf) {
        if (response) {
            return response.status(500).json({ success: false, error: 'O CPF é obrigatório' });
        } else {
            throw new Error('CPF é obrigatório');
        }
    }

    const service = new Service(request, response, {
        name: 'pix-store-generate',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        ordered: true,
        orderingKey: data.cpf,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
