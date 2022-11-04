"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const generateOneTemplate = require('./generateOneTemplate');

const firestoreDAL = require('../../api/firestoreDAL');

// const frontTemplates = firestoreDAL.frontTemplates();
const influencers = firestoreDAL.influencers();
const campanhas = firestoreDAL.campanhas();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            // A campanha já tem o template a ser utilizado...

            const idCampanha = this.parm.data.idCampanha;
            const idInfluencer = this.parm.data.idInfluencer;

            // const idTemplate = this.parm.data.idTemplate;

            const result = {
                success: true,
                host: this.parm.host
            };

            if (!idCampanha) throw new Error(`idCampanha inválido. Informe id ou all`);
            if (!idInfluencer) throw new Error(`idInfluencer inválido. Informe id ou all`);
            // if (!idTemplate) throw new Error(`idTemplate inválido. Informe id ou all`);

            // Carga dos dados
            const promises = [];

            promises.push(idCampanha === 'all' ? campanhas.get() : campanhas.getDoc(idCampanha));
            promises.push(idInfluencer === 'all' ? influencers.get() : influencers.getDoc(idInfluencer));
            // promises.push(idTemplate === 'all' ? frontTemplates.get() : frontTemplates.getDoc(idTemplate));

            return Promise.all(promises)

                .then(promisesResult => {

                    result.campanhas = idCampanha === 'all' ? promisesResult[0] : [promisesResult[0]];
                    result.influencers = idInfluencer === 'all' ? promisesResult[1] : [promisesResult[1]];

                    // result.templates = idTemplate === 'all' ? promisesResult[_frontTemplates] : [promisesResult[_frontTemplates]];

                    const generate = [];

                    /*
                    result.templates.forEach(template => {
                        result.influencers.forEach(influencer => {
                            result.campanhas.forEach(campanha => {
                                generate.push(
                                    generateOneTemplate.call(template.id, influencer.id, campanha.id)
                                )
                            })
                        })
                    })
                    */

                    result.influencers.forEach(influencer => {
                        result.campanhas.forEach(campanha => {
                            generate.push(
                                generateOneTemplate.call(campanha.template, influencer.id, campanha.id)
                            )
                        })
                    })

                    return Promise.all(generate);
                })

                .then(generateResult => {
                    result.generateResult = generateResult;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })

    }

}

exports.Service = Service;

const call = (idInfluencer, idCampanha, request, response) => {
    const service = new Service(request, response, {
        name: 'generate-templates',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        requireIdEmpresa: false,
        data: {
            idInfluencer: idInfluencer,
            idCampanha: idCampanha
        },
        attributes: {
            idEmpresa: idCampanha
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const idInfluencer = request.body.idInfluencer; // Código da empresa
    const idCampanha = request.body.idCampanha;

    if (!idInfluencer || !idCampanha) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idInfluencer, idCampanha, request, response);
}
