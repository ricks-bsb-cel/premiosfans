"use strict";

/*
Tudo o que eu sempre sonhei
Tanto que eu consegui
É tão bom estar aqui
Quanto ainda está por vir?
*/

const global = require('../../global');

// const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');
const _ = require('lodash');
const Joi = require('joi');

const path = require('path');
const eebService = require('../eventBusService').abstract;

const app = require('../../app/home');

const GoogleCloudStorage = require('../../api/googleCloudStorage');
const templateBucket = "premios-fans-templates";
const templateBucketPath = "storage/templates";
const templateStorage = new GoogleCloudStorage(templateBucket, templateBucketPath);

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanhas = firestoreDAL.campanhas();
const collectionCampanhasInfluencers = firestoreDAL.campanhasInfluencers();
const collectionCampanhasSorteios = firestoreDAL.campanhasSorteios();
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

const collectionInfluencers = firestoreDAL.influencers();

const collectionFaq = firestoreDAL.faq();

const schema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        idInfluencer: Joi.string().token().min(18).max(22).required(),
        idTemplate: Joi.string().required()
    });

    return schema;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {
        const version = global.generateRandomId(7);

        const dataResult = await schema().validateAsync(this.parm.data);

        let result = { ...dataResult };

        [
            result.influencer,
            result.campanha,
            result.campanhaInfluencer,
            result.campanhasSorteios,
            result.campanhasSorteiosPremios,
            result.faq
        ] = await Promise.all([
            collectionInfluencers.getDoc(result.idInfluencer),
            collectionCampanhas.getDoc(result.idCampanha),
            collectionCampanhasInfluencers.get({
                filter: [
                    { field: "idCampanha", condition: "==", value: result.idCampanha },
                    { field: "idInfluencer", condition: "==", value: result.idInfluencer }
                ],
                empty: false
            }),
            collectionCampanhasSorteios.get({
                filter: [
                    { field: "idCampanha", condition: "==", value: result.idCampanha },
                ],
                empty: false
            }),
            collectionCampanhasSorteiosPremios.get({
                filter: [
                    { field: "idCampanha", condition: "==", value: result.idCampanha },
                ],
                empty: false
            }),
            collectionFaq.get()
        ]);

        result.version = version;
        result.versionDate = global.todayMoment().toString('DD/MM HH:mm:ss');

        // Ordena os sorteios
        result.campanhaSorteios = _.orderBy(result.campanhasSorteios, ['dtSorteio_yyyymmdd']);

        result.files = await loadTemplateFiles(result.idTemplate);

        if (result.files.length === 0) {
            throw new Error('Invalid template ID');
        }

        result.sendResult = await compileAndSendToStorage(result);

        return {
            success: true,
            files: result.files.length
        }
    }

}

async function compileAndSendToStorage(data) {
    /*
    Este método usa o data.template.files, compilando o conteúdo com o objeto data completo, e
    enviando para 2 diretórios do storage:
        - templates/<idTemplate>/<idCampanha>/<idInfluencer>/min        // Minified
        - templates/<idTemplate>/<idCampanha>/<idInfluencer>/debug      // Normal
    */
    const
        storagePathDebug = `templates/${data.idTemplate}/${data.idCampanha}/${data.idInfluencer}/debug`,
        storagePathMin = `templates/${data.idTemplate}/${data.idCampanha}/${data.idInfluencer}/min`;

    data.env = "debug";
    const promisePathDebug = data.files.map(file => compileAndSaveContentOnStorage(storagePathDebug, file, data));
    const saveFilesResultsDebug = await Promise.all(promisePathDebug);

    data.env = "min";
    const promisePathMin = data.files.map(file => compileAndSaveContentOnStorage(storagePathMin, file, data, path.extname(file.fileName)));
    const saveFilesResultsMin = await Promise.all(promisePathMin);

    return saveFilesResultsDebug.concat(saveFilesResultsMin);
}

async function compileAndSaveContentOnStorage(storagePath, file, obj, minifyExtension) {
    try {
        const storageDest = `${storagePath}/${file.fileName}`;
        const compiledData = await app.compileApp(file.content, obj, minifyExtension);

        await templateStorage.write(storageDest, compiledData)

        return;
    } catch (e) {
        console.error(e);

        throw new Error(e);
    }

    /*
    const storageDest = `${storagePath}/${path.basename(file.name)}`;

    const fileOptions = {
        uploadType: { resumable: false },
        contentType: global.getContentTypeByExtension(storageDest)
    };

    const compiledData = await app.compileApp(file.content, obj);

    const bucket = admin.storage().bucket(obj.template.bucket);
    const storageFile = bucket.file(storageDest, fileOptions);

    storageFile.save(compiledData, e => {
        if (e) {
            console.error(e);

            throw new Error(e);
        } else {
            return {
                bucket: bucket,
                file: storageFile
            };
        }
    });
    */
}

async function loadTemplateFiles(template) { // Resposável por listar os arquivos do template

    const path = templateBucketPath + "/" + template;
    const files = await templateStorage.getFiles(path);
    const promises = files.map(f => templateStorage.read(f.name));

    return await Promise.all(promises);;

    /*
    let [files] = await storage.bucket(template.bucket).getFiles({
        prefix: template.storagePathDev,
        versions: false,
        autoPaginate: false
    });

    files = files.map(f => {
        return {
            name: f.name,
            file: f,
            metadata: {
                id: f.metadata.id,
                size: f.metadata.size
            }
        };
    });

    const promises = files.map(f => getFileContent(f.file));
    const filesContent = await Promise.all(promises);

    filesContent.forEach((c, i) => {
        files[i].content = c;

        // Não preciso mais do objeto File
        delete files[i].file;
    })

    return files;
    */
}

/*
async function getFileContent(file) { // Responsável por carregar o conteúdo do arquivo do Storage
    return new Promise((resolve, reject) => {

        console.log('getFileContent');
        console.log(file.name, file.generation || 'void');

        // Caminho correto: premios-fans.appspot.com/storage/prod/templates/venda-with-messaging
        // Caminho no Log:                           storage/dev/templates/venda-with-messaging/index.js

        const streamToString = (stream, callback) => {
            const chunks = [];
            stream.on('data', (chunk) => { chunks.push(chunk.toString()); });
            stream.on('end', () => { callback(chunks.join('')); });
        }

        const bufferToStream = buffer => {
            const Readable = require('stream').Readable;
            const stream = new Readable();
            stream.push(buffer);
            stream.push(null);
            return stream;
        }

        const options = {
            customHeaders: {
                'Cache-Control': 'no-cache'
            }
        };

        return file.download(options, function (e, contents) {
            if (!e) {
                const stream = bufferToStream(contents);
                streamToString(stream, result => {
                    return resolve(result);
                })
            } else {
                console.error(e);
                return reject(e.code);
            }
        });
    })
}
*/

exports.Service = Service;

const call = (idTemplate, idInfluencer, idCampanha, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'generate-one-template',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: {
            idTemplate: idTemplate,
            idInfluencer: idInfluencer,
            idCampanha: idCampanha
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const idTemplate = request.body.idTemplate;
    const idInfluencer = request.body.idInfluencer; // Código da empresa
    const idCampanha = request.body.idCampanha;

    if (!idTemplate || !idInfluencer || !idCampanha) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idTemplate, idInfluencer, idCampanha, request, response);
}
