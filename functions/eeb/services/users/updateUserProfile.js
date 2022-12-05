"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;
const global = require("../../../global");

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const getUserProfile = require('./getUserProfile');
const firestoreDAL = require('../../../api/firestoreDAL');

const collectionUserProfile = firestoreDAL.userProfile();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                uid: this.parm.user_uid
            };

            let updateUserProfile;

            return getUserProfile.get(result.uid)

                .then(getUserResult => {
                    updateUserProfile = getUserResult;

                    if (updateUserProfile.isAnonymous) {
                        throw new Error(`Usuários anonimos não podem ser atualizados`);
                    }

                    global.setDateTime(updateUserProfile, 'dtAlteracao');

                    updateUserProfile.keywords = global.generateKeywords(
                        updateUserProfile.displayName,
                        updateUserProfile.email
                    );

                    delete updateUserProfile.customClaims;

                    updateUserProfile.keywords.push(updateUserProfile.uid);

                    return collectionUserProfile.set(updateUserProfile.uid, updateUserProfile, true);
                })

                .then(_ => {
                    result.data = updateUserProfile;

                    delete result.data.keywords;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'update-user-profile',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: {},
        auth: eebAuthTypes.tokenNotAnonymous
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request, response);
}
