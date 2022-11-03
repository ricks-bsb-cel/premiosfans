"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;

const firestoreDAL = require('../../api/firestoreDAL');
const collectionEebTest = firestoreDAL.eebTest();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

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
    const service = new Service(request, response, {
        name: 'test',
        async: request.query.async ? request.query.async === 'true' : false,
        debug: request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        attributes: {
            idEmpresa: 'all'
        }
    });

    return service.init();
}

exports.callRequest = (request, response) => {
    return call(request.body || {}, request, response)

}
