"use strict";

const eebService = require('../eventBusService').abstract;

const firestoreDAL = require('../../api/firestoreDAL');
const collectionConfigProfiles = firestoreDAL.admConfigProfiles();

const { getAuth } = require("firebase-admin/auth");

const idSuperUser = "RaxbGarlPwgSeM64PKr0lpMBlHb2";
const idConfigProfileSuperUser = "bIOIFnaGz7CYUsS1WA9P";

const _get = (uid, withProfile) => {
    return new Promise((resolve, reject) => {

        let result;

        return getAuth().getUser(uid)

            .then(getUserResult => {

                result = {
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
                    result.customClaims.idConfigProfile = idConfigProfileSuperUser;
                }

                if (Object.keys(result.customClaims).length === 0) {
                    delete result.customClaims;
                }

                if (withProfile && result.customClaims && result.customClaims.idConfigProfile) {
                    return collectionConfigProfiles.getDoc(result.customClaims.idConfigProfile);
                } else {
                    return null;
                }

            })

            .then(userProfile => {
                result.userProfile = userProfile || null;

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            });

    })
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {

        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                uid: this.parm.data.uid,
                withProfile: this.parm.data.withProfile
            };

            if (result.uid === 'current') {
                result.uid = this.parm.user_uid;
            }

            return _get(result.uid, result.withProfile)

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

const call = (uid, withProfile, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'get-user-profile',
        async: false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: {
            uid: uid,
            withProfile: withProfile
        },
        auth: eebAuthTypes.tokenNotAnonymous
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const uid = request.params.uid || null;
    const withProfile = request.query ? request.query['with-profile'] === 'true' : false

    return call(uid, withProfile, request, response);
}
