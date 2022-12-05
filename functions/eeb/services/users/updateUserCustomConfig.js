"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;
const Joi = require('joi');

const { getAuth } = require("firebase-admin/auth");

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const getUserProfile = require("./getUserProfile");

const schema = _ => {
    const schema = Joi.object({
        uid: Joi.string().token().min(18).max(22).required(),
        isAdmin: Joi.boolean().optional(),
        isSuperUser: Joi.boolean().optional(),
        idConfigProfile: Joi.string().token().min(18).max(22).optional()
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

            const result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)
                .then(dataResult => {
                    result.request = dataResult;

                    // Verifica acesso do usuário do token atual
                    return getUserProfile.call(this.parm.user_uid);
                })

                .then(currentUser => {
                    result.currentUser = currentUser;

                    if (!currentUserResult.customClaims.superUser) {
                        throw new Error(`O usuário atual não é Administrador ou SuperUsuário`)
                    }

                    return getUserProfile.call(result.request.uid)
                })

                .then(userToChange => {
                    result.userToChange = userToChange;

                    return resolve(this.parm.async ? { success: true } : result);
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

    const service = new Service(request, response, {
        name: 'update-user-custom-config',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.tokenNotAnonymous
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
