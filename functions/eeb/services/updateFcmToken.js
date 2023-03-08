"use strict";

const admin = require("firebase-admin");

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const firestoreDAL = require('../../api/firestoreDAL');

const collectionFcmTokens = firestoreDAL.fcmTokens();
const collectionCampanha = firestoreDAL.campanhas();

const schema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        fcmToken: Joi.string().min(32).max(512).required(),
        guidUser: Joi.string().min(16).max(64).required(),
        uidUser: Joi.string().token().max(512).optional()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {

        let
            toSave = {},
            currentDoc = null,
            user = null;
        const result = {
            campanha: null,
            success: true,
            host: this.parm.host,
            parm: {}
        };

        result.parm = await schema().validateAsync(this.parm.data);

        if (result.parm.uidUser) {
            user = await admin.auth().getUser(result.parm.uidUser);

            if (!user) {
                throw new Error('User not found...');
            }
        }

        // Tenta localizar pelo UID do usuário
        if (result.parm.uidUser) {
            currentDoc = await collectionFcmTokens.get({
                filter: { uidUser: result.parm.uidUser },
                limit: 1
            })
        }

        // Se não localizado pelo UID do Usuário, tenta localizar pelo token mesmo
        if (!currentDoc || currentDoc.length === 0) {
            currentDoc = await collectionFcmTokens.get({
                filter: { fcmToken: result.parm.fcmToken },
                limit: 1
            })
        }

        // Valida se a campanha realmente existe
        if (result.parm.idCampanha) {
            result.campanha = await collectionCampanha.getDoc(result.parm.idCampanha);
        }

        if (currentDoc.length > 0) {
            toSave = { ...currentDoc[0], ...result.parm };
        } else {
            toSave = result.parm;
        }

        toSave.campanhas = toSave.campanhas || [];

        if (!toSave.campanhas.includes(toSave.idCampanha)) {
            toSave.campanhas.push(toSave.idCampanha);
        }

        delete toSave.idCampanha;

        const insertUpdateResult = await collectionFcmTokens.insertUpdate(toSave.id || null, toSave);

        return insertUpdateResult;
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

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
    return call(request.body, request, response);
}
