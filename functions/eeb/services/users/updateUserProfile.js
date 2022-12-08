"use strict";

const admin = require("firebase-admin");

const path = require('path');
const eebService = require('../../eventBusService').abstract;
const global = require("../../../global");
const helper = require("../../eventBusServiceHelper");

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const getUserProfile = require('./getUserProfile');
const firestoreDAL = require('../../../api/firestoreDAL');

const collectionUserProfile = firestoreDAL.userProfile();

const _updateWithToken = (request, response) => {
    return new Promise((resolve, reject) => {

        const token = helper.getUserTokenFromRequest(request, response);

        if (!token) return resolve(null);

        return admin.auth().verifyIdToken(token)
            .then(userTokenDetails => {
                return _updateWithUid(userTokenDetails.uid, true);
            })

            .then(result => {
                return resolve(result);
            })

            .catch(e => {
                if (e.code === 'auth/id-token-expired') {
                    return resolve(null);
                } else {
                    return reject(e);
                }
            })

    })
}

const _updateWithUid = (uid, withProfile) => {

    const result = {
        success: true,
        uid: uid
    };

    let updateUserProfile;

    return new Promise((resolve, reject) => {

        return getUserProfile.get(result.uid)

            .then(getUserResult => {
                updateUserProfile = getUserResult;

                if (updateUserProfile.isAnonymous) {
                    const e = Error(`Usuários anonimos não podem ser atualizados`);
                    e.code = 'invalid-anonymous-user'
                    throw e;
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
                return getUserProfile.get(result.uid, withProfile);
            })

            .then(result => {
                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })
    })
}


class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            return _updateWithUid(this.parm.user_uid)

                .then(result => {
                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;
exports.updateWithToken = _updateWithToken;

const call = (request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'update-user-profile',
        async: request && request.query.async ? request.query.async === 'true' : false,
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
