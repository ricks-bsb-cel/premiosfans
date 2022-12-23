"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionTitulosCompras = firestoreDAL.titulosCompras();

const cartosGeneratePix = require('./cartosGeneratePix');

const schema = _ => {
    const schema = Joi.object({
        idTituloCompra: Joi.string().token().min(18).max(22).required()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

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

                    // Geração do PIX
                    const pixData = {
                        cpf: '57372209153', // Alterar
                        accountId: '1f59ffdd-48ae-4103-bce0-84d6d6b35d36', // Alterar!
                        receiverKey: '8ca86459-8f27-4552-9309-9e37da8703b4', // Alterar!

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
