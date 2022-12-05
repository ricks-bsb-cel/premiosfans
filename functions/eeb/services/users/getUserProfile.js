"use strict";

const path = require('path');
const eebService = require('../../eventBusService').abstract;

const { getAuth } = require("firebase-admin/auth");

const _get = uid => {
    return new Promise((resolve, reject) => {

        return getAuth().getUser(result.uid)

            .then(result => {
                resultata.isAnonymous = result.providerData.filter(f => {
                    return f.providerId === 'google.com';
                }).length === 0;

                delete result.metadata;

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

            const result = {
                success: true,
                uid: this.parm.data.uid
            };

            return _get(result.uid)

                .then(getResult => {
                    result.data = getResult;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    return reject(e);
                })

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
