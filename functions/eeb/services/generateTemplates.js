"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;

const firestoreDAL = require('../../api/firestoreDAL');

const frontTemplates = firestoreDAL.frontTemplates();
const influencers = firestoreDAL.influencers();
const campanhas = firestoreDAL.campanhas();

const _frontTemplates = 0;
const _influencers = 1;
const _campanhas = 2;

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const idTemplate = this.parm.data.idTemplate;
            const idInfluencer = this.parm.data.idInfluencer;
            const idCampanha = this.parm.data.idCampanha;

            const result = {
                success: true
            };

            if (!idTemplate) throw new Error(`idTemplate inválido. Informe id ou all`);
            if (!idInfluencer) throw new Error(`idInfluencer inválido. Informe id ou all`);
            if (!idCampanha) throw new Error(`idCampanha inválido. Informe id ou all`);

            // Carga dos dados
            let promises = [];

            promises.push(idTemplate === 'all' ? frontTemplates.get() : frontTemplates.getDoc(idTemplate));
            promises.push(idInfluencer === 'all' ? influencers.get() : influencers.getDoc(idInfluencer));
            promises.push(idCampanha === 'all' ? campanhas.get() : campanhas.getDoc(idCampanha));

            return Promise.all(promises)
                .then(promisesResult => {
                    result.templates = idTemplate === 'all' ? promisesResult[_frontTemplates] : [promisesResult[_frontTemplates]];
                    result.influencers = idInfluencer === 'all' ? promisesResult[_influencers] : [promisesResult[_influencers]];
                    result.campanhas = idCampanha === 'all' ? promisesResult[_campanhas] : [promisesResult[_campanhas]];

                    return resolve(result)
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

exports.call = (request, response) => {

    const idTemplate = request.body.idTemplate;
    const idInfluencer = request.body.idInfluencer; // Código da empresa
    const idCampanha = request.body.idCampanha;

    if (!idTemplate || !idInfluencer || !idCampanha) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    const service = new Service(request, response, {
        name: 'generate-templates',
        async: request.query.async ? request.query.async === 'true' : true,
        debug: request.query.debug ? request.query.debug === 'true' : false,
        requireIdEmpresa: false,
        data: {
            idTemplate: idTemplate,
            idInfluencer: idInfluencer,
            idCampanha: idCampanha
        },
        attributes: {
            idEmpresa: idCampanha
        }
    });

    return service.init();
}
