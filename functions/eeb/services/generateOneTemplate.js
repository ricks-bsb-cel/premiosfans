"use strict";

const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');

const path = require('path');
const eebService = require('../eventBusService').abstract;

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');
const global = require('../../global');

const collectionFrontTemplates = firestoreDAL.frontTemplates();
const collectionInfluencers = firestoreDAL.influencers();
const collectionCampanhas = firestoreDAL.campanhas();

const storage = new Storage();

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
                success: true,
                host: this.parm.host
            };

            if (!idTemplate) throw new Error(`idTemplate inválido. Informe idTemplate`);
            if (!idInfluencer) throw new Error(`idInfluencer inválido. Informe idInfluencer`);
            if (!idCampanha) throw new Error(`idCampanha inválido. Informe idCampanha`);

            // Carga dos dados
            const promises = [
                collectionFrontTemplates.getDoc(idTemplate),
                collectionInfluencers.getDoc(idInfluencer),
                collectionCampanhas.getDoc(idCampanha)
            ];

            return Promise.all(promises)
                .then(promisesResult => {
                    result.template = promisesResult[0];
                    result.influencer = promisesResult[1];
                    result.campanha = promisesResult[2];

                    return loadTemplateFiles(result.template);
                })

                .then(files => {
                    result.template.files = files;

                    return compileAndSendToStorage(result.template, result.influencer, result.campanha);
                })

                .then(sendResult => {
                    result.sendResult = sendResult;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })
    }

}

const compileAndSendToStorage = (template, influencer, campanha) => {
    return new Promise((resolve, reject) => {

        // app/<idInfluencer>/<idCampanha>
        const storagePath = `app/${influencer.id}/${campanha.id}`;

        const obj = {
            template: template,
            influencer: influencer,
            campanha: campanha
        };

        campanha.imagePrincipal = campanha.images[0].secure_url;

        const promises = [];

        template.files.forEach(file => {
            const storageDest = `${storagePath}/${path.basename(file.name)}`;
            const content = global.compile(file.content, obj);

            promises.push(
                saveContentOnStorage(
                    template.bucket,
                    storageDest,
                    content,
                    template.nome,
                    influencer.id,
                    campanha.id
                )
            )
        });

        return Promise.all(promises)

            .then(saveFilesResults => {
                return resolve(
                    saveFilesResults.map(f => {
                        return {
                            bucket: f.bucket.name,
                            fileName: f.file.name
                        }
                    })
                );
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const saveContentOnStorage = (bucketName, fileName, content, idTemplate, idInfluencer, idCampanha) => {
    return new Promise((resolve, reject) => {

        const fileOptions = {
            uploadType: { resumable: false },
            contentType: global.getContentTypeByExtension(fileName)
        };

        const bucket = admin.storage().bucket(bucketName);
        const storageFile = bucket.file(fileName, fileOptions);

        storageFile.save(content, e => {
            if (e) {
                console.error(e);
                return reject(e);
            } else {
                return resolve(
                    {
                        bucket: bucket,
                        file: storageFile,
                        idTemplate: idTemplate,
                        idInfluencer: idInfluencer,
                        idCampanha: idCampanha
                    }
                );
            }
        });

    })
}

const loadTemplateFiles = template => { // Resposável por buscar os templates no Storage
    return new Promise((resolve, reject) => {

        let files;

        storage.bucket(template.bucket).getFiles({
            prefix: template.storagePathDev
        })

            .then(([getFilesResult]) => {
                files = getFilesResult;

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

                const promises = [];

                files.forEach(f => {
                    promises.push(getFileContent(f.file));
                })

                return Promise.all(promises);
            })

            .then(filesContent => {
                filesContent.forEach((c, i) => {
                    files[i].content = c;

                    // Não preciso mais do objeto File
                    delete files[i].file;
                })

                return resolve(files);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const getFileContent = file => { // Responsável por carregar o conteúdo do arquivo do Storage
    return new Promise((resolve, reject) => {

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

        return file.download(function (e, contents) {
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

exports.Service = Service;

const call = (idTemplate, idInfluencer, idCampanha, request, response) => {

    const service = new Service(request, response, {
        name: 'generate-one-template',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
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
