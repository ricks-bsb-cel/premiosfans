"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;

const { getAuth } = require("firebase-admin/auth");

const idSuperUser = "RaxbGarlPwgSeM64PKr0lpMBlHb2";

const _get = uid => {
    return new Promise((resolve, reject) => {

        return getAuth().getUser(uid)

            .then(getUserResult => {

                let result = {
                    uid: getUserResult.uid,
                    email: getUserResult.email || null,
                    emailVerified: getUserResult.emailVerified,
                    displayName: getUserResult.displayName || null,
                    photoURL: getUserResult.photoURL || null,
                    phoneNumber: getUserResult.phoneNumber || null,
                    disabled: getUserResult.disabled,
                    customClaims: getUserResult.customClaims || {},
                    isAnonymous: getUserResult.providerData.filter(f => {
                        return f.providerId === 'google.com';
                    }).length === 0
                };

                if (result.uid === idSuperUser) {
                    result.customClaims.superUser = true;
                }

                if (Object.keys(result.customClaims).length === 0) {
                    delete result.customClaims;
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            });

    })
}

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

            if (result.uid === 'current') {
                result.uid = this.parm.user_uid;
            }

            return _get(result.uid)

                .then(getResult => {
                    result.data = getResult;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    return reject(e);
                });

        })
    }

}

exports.Service = Service;
exports.get = _get;

const call = (uid, request, response) => {
    const eebAuthTypes = require('../../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'get-user-profile',
        async: false,
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

    return call(uid, request, response);
}
