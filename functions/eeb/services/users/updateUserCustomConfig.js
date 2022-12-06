"use strict";

const path = require('path');
const admin = require("firebase-admin");
const eebService = require('../../eventBusService').abstract;
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const getUserProfile = require("./getUserProfile");
const firestoreDAL = require("../../../api/firestoreDAL");
const collectionConfigProfiles = firestoreDAL.admConfigProfiles();

const schema = _ => {
    const schema = Joi.object({
        uid: Joi.string().token().min(18).max(32).required(),
        adminUser: Joi.boolean().optional(),
        superUser: Joi.boolean().optional(),
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

            let configProfile,
                result = {
                    success: true
                };

            return schema().validateAsync(this.parm.data)
                .then(dataResult => {
                    result.uid = dataResult.uid;
                    result.custom = dataResult;

                    delete result.custom.uid;

                    if (result.custom.superUser && result.custom.adminUser) {
                        throw new Error(`Configuração inválida`);
                    }

                    // Verifica acesso do usuário do token atual
                    return getUserProfile.get(this.parm.user_uid);
                })

                .then(currentUser => {
                    result.currentUser = currentUser;

                    if (result.currentUser.customClaims && !result.currentUser.customClaims.superUser) {
                        throw new Error(`O usuário atual ${result.currentUser.email} não é Administrador ou SuperUsuário`)
                    }

                    return getUserProfile.get(result.uid)
                })

                .then(userToChange => {
                    result.userToChange = userToChange;

                    if (result.userToChange.isAnonymous) {
                        throw new Error(`Não é possível aplicar configurações para usuários anônimos`)
                    }

                    if (result.custom.idConfigProfile) {
                        return collectionConfigProfiles.getDoc(result.custom.idConfigProfile);
                    } else {
                        return true;
                    }
                })
                .then(configProfileResult => {
                    configProfile = configProfileResult;

                    return admin.auth().setCustomUserClaims(result.uid, result.custom);
                })

                .then(_ => {
                    return getUserProfile.get(result.uid)
                })

                .then(getUserProfileResult => {
                    result = {
                        success: true,
                        data: getUserProfileResult,
                    }

                    if (typeof configProfile === 'object') {
                        result.data.ConfigProfile = configProfile;
                    }

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
