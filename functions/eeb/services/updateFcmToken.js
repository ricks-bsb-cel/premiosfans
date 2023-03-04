"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

const firestoreDAL = require('../../api/firestoreDAL');

const collectionFcmTokens = firestoreDAL.fcmTokens();

const schema = _ => {
    const schema = Joi.object({
        fcmToken: Joi.string().token().max(512).required(),
        guidUser: Joi.string().token().min(16).max(64).required(),
        userUid: Joi.string().token().max(512).optional()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {

        const
            toSave = {},
            result = {
                success: true,
                host: this.parm.host,
                data: {}
            };

        result.data = await schema().validateAsync(this.parm.data);

        // Verifica se o token já existe (ele é a chave de tudo)
        const currentToken = await collectionFcmTokens.get({
            filter: { fcmToken: data.fcmToken },
            limit: 1
        })

        if (currentToken.length > 0) {
            toSave = currentToken[0];
        } else {
            toSave = result.data;
            global.setDateTime(toSave, 'inclusao');
        }

        global.setDateTime(toSave, 'alteracao');

        return await collectionFcmTokens.insertUpdate(toSave.id || null, toSave);
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    if (!data.idCampanha) {
        throw new Error('invalid parm');
    }

    const service = new Service(request, response, {
        name: 'update-fcm-token',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.noAuth
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {

    if (!request.body) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
