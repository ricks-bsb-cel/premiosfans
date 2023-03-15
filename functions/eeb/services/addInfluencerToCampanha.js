"use strict";

const eebService = require('../eventBusService').abstract;
const global = require("../../global");
const Joi = require('joi');

const GoogleCloudStorage = require('../../api/googleCloudStorage');
const templateBucket = "premios-fans-templates";
const templateStorage = new GoogleCloudStorage(templateBucket);

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanha = firestoreDAL.campanhas();
const collectionInfluencer = firestoreDAL.influencers();
const collectionCampanhasInfluencers = firestoreDAL.campanhasInfluencers()

const schema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        idInfluencer: Joi.string().token().min(18).max(22).required(),
        ativo: Joi.boolean().default(true).optional(),
        idTemplate: Joi.string().min(3).max(64).optional()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {
        const result = {
            success: true,
            host: this.parm.host,
            data: {}
        };

        result.data = await schema().validateAsync(this.parm.data);

        const promiseResult = await Promise.all([
            collectionCampanha.getDoc(result.data.idCampanha),
            collectionInfluencer.getDoc(result.data.idInfluencer),
            collectionCampanhasInfluencers.get({
                filter: [
                    { field: "idCampanha", condition: "==", value: result.data.idCampanha },
                    { field: "idInfluencer", condition: "==", value: result.data.idInfluencer },
                ],
                limit: 1
            })
        ])

        const id = promiseResult[2] && promiseResult[2].length ? promiseResult[2][0].id : null;

        let toAdd = promiseResult[2] && promiseResult[2].length ? promiseResult[2][0] : {
            idCampanha: result.data.idCampanha,
            idInfluencer: result.data.idInfluencer
        };

        if (result.data.idTemplate) toAdd.idTemplate = result.data.idTemplate;

        if (result.data.idTemplate) {
            const templateDir = `storage/templates/${result.data.idTemplate}`;
            const templateExist = await templateStorage.directoryExists(templateDir);

            if (!templateExist) throw new Error(`O template ${result.data.idTemplate} não foi encontrado em ${templateBucket}/${templateDir}`);
        
            toAdd.idTemplate = result.data.idTemplate;
        }

        toAdd.ativo  = result.data.ativo;
        
        if (!id) global.setDateTime(toAdd, 'dtInclusao');
        global.setDateTime(toAdd, 'dtAlteracao');

        return await collectionCampanhasInfluencers.set(id, toAdd, true);
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'add-influencer-to-campanha',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.tokenNotAnonymous
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
