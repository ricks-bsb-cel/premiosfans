"use strict";

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
o Pré-Generate PIX gera um PIX e o deixa pronto para uso em uma compra futura.
Os PIXs pre gerados são armazenados na colection cartosPixPreGenerated, e não estão vinculados
à nenhuma compra.
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionTitulosCompras = firestoreDAL.titulosCompras();
const collectionCampanha = firestoreDAL.campanhas();

const cartosGeneratePix = require('./cartos/cartosGeneratePix');

const schema = _ => {
    const schema = Joi.object({
        cpf: Joi.string().token().min(11).required().required(),
        accountId: Joi.string().token().length(36).required(),
        key: Joi.string().required(),
        valor: Joi.number().min(1).max(999999).required()s
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
        name: 'pix-store-generate',
        async: request && request.query.async ? request.query.async === 'true' : false,
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
