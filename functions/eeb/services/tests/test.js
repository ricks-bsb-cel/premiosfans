"use strict";

const eebService = require('../../eventBusService').abstract;

const firestoreDAL = require('../../../api/firestoreDAL');
const collectionEebTest = firestoreDAL.eebTest();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const toAdd = {
                async: this.parm.async,
                attributes: this.parm.attributes,
                data: this.parm.data,
                method: this.parm.method,
                serviceId: this.parm.serviceId
            };

            return collectionEebTest.add(toAdd)

                .then(addResult => {
                    return resolve({
                        success: true,
                        id: addResult.id
                    })
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

    const parm = {
        name: 'test',
        async: request.query.async ? request.query.async === 'true' : false,
        debug: request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.noAuth
    };

    if (data.delay) {
        parm.delay = data.delay;
        delete data.delay;
    }

    const service = new Service(request, response, parm);

    return service.init();
}

exports.callRequest = (request, response) => {
    return call(request.body || {}, request, response)
}
