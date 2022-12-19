"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;
const { getAuth } = require("firebase-admin/auth");


/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const getUserProfile = require("./usersGetUserProfile");

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                uid: this.parm.data.uid
            };

            return getUserProfile.get(result.uid)

                .then(user => {
                    result.user = user;

                    return getAuth().revokeRefreshTokens(result.uid);
                })

                .then(_ => {
                    result.revoked = true;

                    delete result.user;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    return reject(e);
                })

        })

    }
}

exports.Service = Service;

const call = (uid, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'revoke-user-token',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: {
            uid: uid
        },
        auth: eebAuthTypes.tokenNotAnonymous
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const uid = request.params.uid || null;

    if (!uid) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }
    return call(uid, request, response);
}
