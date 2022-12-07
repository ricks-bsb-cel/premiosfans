"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;

const firestoreDAL = require('../../api/firestoreDAL');
const collectionWebHook = firestoreDAL._webHookReceived();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const toAdd = {
                data: this.parm.data,
                attributes: this.parm.attributes,
                method: this.parm.method,
                serviceId: this.parm.serviceId
            };

            return collectionWebHook.add(toAdd)

                .then(addResult => {
                    toAdd.id = addResult.id;
                    return resolve(toAdd)
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

exports.callRequest = (request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const parm = {
        name: 'webhook',
        async: request.query.async ? request.query.async === 'true' : true,
        debug: request.query.debug ? request.query.debug === 'true' : false,
        data: request.body || {},
        auth: eebAuthTypes.noAuth,
        attributes: {
            source: request.params.source
        }
    };

    if (request.params.type) {
        parm.attributes.type = request.params.type;
    }

    const service = new Service(request, response, parm);

    return service.init();
}
