"use strict";

const Joi = require('joi');
const eebService = require('../../eventBusService').abstract;
const global = require('../../../global');

const userCredentials = require('./cartosGetUserCredential');
const cartosHttpRequest = require('./cartosHttpRequests');

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionCartosPix = firestoreDAL.cartosPix();
const collectionTituloCompra = firestoreDAL.titulosCompras();

const acompanhamentoTituloCompra = require('../acompanhamentoTituloCompra');

/*
    Cria um PIX para pagamento e o salva na collection cartosPix
    Também cola o PIX no tituloCompra
*/

const schema = _ => {
    return Joi.object({
        cpf: Joi.string().length(11).required(),
        accountId: Joi.string().required(),
        type: Joi.string().valid('STATIC', 'DYNAMIC').required(),
        receiverKey: Joi.string().required(),
        merchantCity: Joi.string().required(),
        value: Joi.when('type', {
            switch: [
                { is: 'STATIC', then: Joi.number().positive().optional() },
                { is: 'DYNAMIC', then: Joi.number().positive().required() }
            ]
        }),
        additionalInfo: Joi.string().max(37).required(),
        user_uid: Joi.string().min(1).max(128).optional(),
        idTituloCompra: Joi.string().token().min(18).max(22).optional()
    });
}

async function generatePix(data, tituloCompra, serviceId) {
    const credential = await userCredentials.getCredential(data.cpf, data.accountId);
    let pix = await cartosHttpRequest.generatePix(data, credential.token);

    const update = { ...data };

    update.serviceId = serviceId;
    delete update.accountId;
    global.setDateTime(update, 'dtInclusao');

    pix = { ...pix, ...update };

    // Salva os dados na Collection PIX
    await collectionCartosPix.add(pix)

    await collectionTituloCompra.merge(tituloCompra.id, { pix: pix });
    await acompanhamentoTituloCompra.setPixData(tituloCompra, pix);

    return pix;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {
            const result = {};

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return collectionTituloCompra.getDoc(result.parm.idTituloCompra);
                })
                .then(tituloCompraResult => {
                    result.tituloCompra = tituloCompraResult;

                    return generatePix(result.parm, result.tituloCompra, this.parm.serviceId);
                })

                .then(generatePixResult => {
                    return resolve(this.parm.async ? { success: true } : generatePixResult);
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    if (!data.cpf) throw new Error('o CPF é obrigatório...');

    const service = new Service(request, response, {
        name: 'update-cartos-data',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        ordered: true,
        orderingKey: data.cpf,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
