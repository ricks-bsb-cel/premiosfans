"use strict";

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js

Esta é a rotina responsável por solicitar um PIX (mas não o "cola" na compra)

*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionTitulosCompras = firestoreDAL.titulosCompras();
const collectionCampanha = firestoreDAL.campanhas();

const cartosGeneratePix = require('./cartos/cartosGeneratePix');

const schema = _ => {
    const schema = Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return collectionTitulosCompras.getDoc(result.parm.idTituloCompra);
                })

                .then(resultTituloCompra => {
                    result.tituloCompra = resultTituloCompra;

                    if (result.tituloCompra.situacao !== 'aguardando-pagamento') throw new Error(`A compra ${result.parm.idTituloCompra} não está em situação que permita pagamento.`);

                    return collectionCampanha.getDoc(result.tituloCompra.idCampanha);
                })

                .then(resultCampanha => {

                    if (!resultCampanha.pixKeyCredito || !resultCampanha.pixKeyCredito_accountId || !resultCampanha.pixKeyCredito_cpf) throw new Error(`A compra ${result.parm.idTituloCompra} pertence a uma campanha sem PIX de pagamento configurado.`);

                    // Geração do PIX
                    const pixData = {
                        cpf: resultCampanha.pixKeyCredito_cpf,
                        accountId: resultCampanha.pixKeyCredito_accountId,
                        receiverKey: resultCampanha.pixKeyCredito,

                        type: 'STATIC',
                        merchantCity: 'João Pessoa/PB',
                        value: result.tituloCompra.vlTotalCompra * 100,
                        additionalInfo: `PremiosFans ${result.tituloCompra.id}`,
                        user_uid: result.tituloCompra.uidComprador,
                        idTituloCompra: result.parm.idTituloCompra
                    };

                    return cartosGeneratePix.call(pixData);
                })

                .then(cartosGeneratePixResult => {
                    result = {
                        success: true,
                        idTituloCompra: result.tituloCompra.id,
                        pixService: cartosGeneratePixResult
                    };

                    return resolve(result);
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

    const service = new Service(request, response, {
        name: 'generate-pedido-pagamento-compra',
        async: false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
