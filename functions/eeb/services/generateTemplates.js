/*
    Este script solicita a geração de todos os templates para cada um dos influencers selecionados na(s) campanha(s)
*/
"use strict";

const eebService = require('../eventBusService').abstract;

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const generateOneTemplate = require('./generateOneTemplate');

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanhas = firestoreDAL.campanhas();
const collectionCampanhasInfluencers = firestoreDAL.campanhasInfluencers();

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            // A campanha já tem o template a ser utilizado...
            // A campanha já tem os influencers vinculados

            const idCampanha = this.parm.data.idCampanha,
                idInfluencer = this.parm.data.idInfluencer,
                result = {
                    success: true,
                    host: this.parm.host
                };

            if (!idCampanha) throw new Error(`idCampanha inválido. Informe id ou all para todas as campanhas ativas`);
            if (!idInfluencer) throw new Error(`idInfluencer inválido. Informe id ou all para todos os influencers selecionados na campanha`);

            return idCampanha === 'all' ? collectionCampanhas.get() : collectionCampanhas.getDoc(idCampanha)

                .then(campanhaResults => {

                    result.campanhas = idCampanha === 'all' ? campanhaResults : [campanhaResults];

                    const idsCampanhas = [];

                    result.campanhas.forEach(c => {
                        idsCampanhas.push(c.id);
                    });

                    const filterInfluencesCampanha = [
                        { field: "idCampanha", condition: "in", value: idsCampanhas },
                        { field: "selected", condition: "==", value: true }
                    ];

                    if (idInfluencer !== 'all') {
                        filterInfluencesCampanha.push(
                            { field: "idInfluencer", condition: "==", value: idInfluencer }
                        )
                    }

                    return collectionCampanhasInfluencers.get({ filter: filterInfluencesCampanha });
                })

                .then(resultCampanhasInfluencers => {

                    result.campanhasInfluencers = resultCampanhasInfluencers;

                    // result.campanhas contem todas as campanhas
                    // result.campanhasInfluencers contem todos os influencers das campanhas

                    const generate = [];

                    result.campanhas.forEach(campanha => {
                        result.campanhasInfluencers
                            .filter(f => { return f.idCampanha === campanha.id })
                            .forEach(influencer => {
                                this.log('generate-template', 'INFO', {
                                    template: campanha.template,
                                    influencer: influencer.idInfluencer,
                                    campanha: campanha.idCampanha
                                });

                                generate.push(
                                    generateOneTemplate.call(campanha.template, influencer.idInfluencer, campanha.id)
                                )
                            })
                    })

                    return Promise.all(generate);
                })

                .then(generateResult => {
                    result.generateResult = generateResult;

                    return resolve(this.parm.async ? { success: true } : {
                        success: true,
                        host: result.host,
                        campanhas: result.campanhas.map(c => {
                            return {
                                id: c.id,
                                titulo: c.titulo,
                                influencers: result.campanhasInfluencers
                                    .filter(f => { return f.idCampanha === c.id; })
                                    .map(i => {
                                        return {
                                            idCampanha: i.idCampanha,
                                            idInfluencer: i.idInfluencer,
                                            selected: i.selected
                                        }
                                    })
                            }
                        })
                    });
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
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'generate-templates',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.tokenNotAnonymous,
        data: {
            idInfluencer: idInfluencer,
            idCampanha: idCampanha
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
