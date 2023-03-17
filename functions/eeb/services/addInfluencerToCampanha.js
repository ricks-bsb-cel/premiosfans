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

        try {

            let [
                campanha,
                influencer,
                campanhaInfluencer
            ] = await Promise.all([
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

            if (!campanha) throw new Error('Campanha não existe');
            if (!influencer) throw new Error('Influencer não existe');

            // O influencer pode ou não já estár vinculado à campanha
            campanhaInfluencer = campanhaInfluencer && campanhaInfluencer.length ? campanhaInfluencer[0] : null;

            const id = campanhaInfluencer ? campanhaInfluencer.id : null;
            const toAdd = campanhaInfluencer || {
                idCampanha: result.data.idCampanha,
                idInfluencer: result.data.idInfluencer
            };

            // Todo influencer ou tem um template ou usa o que já está selecionado na Campanha
            toAdd.idTemplate = result.data.idTemplate || campanha.idTemplate || campanha.template;

            const templateDir = `storage/templates/${toAdd.idTemplate}`;
            const templateExist = await templateStorage.directoryExists(templateDir);

            if (!templateExist) throw new Error(`O template ${result.data.idTemplate} não foi encontrado em ${templateBucket}/${templateDir}`);

            toAdd.ativo = result.data.ativo;

            if (!id) global.setDateTime(toAdd, 'dtInclusao');
            global.setDateTime(toAdd, 'dtAlteracao');

            return await collectionCampanhasInfluencers.set(id, toAdd, true);
        } catch (e) {
            console.error(e);

            throw new Error(e);
        }
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
