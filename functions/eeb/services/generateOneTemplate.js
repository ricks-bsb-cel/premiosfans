"use strict";

const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');

const path = require('path');
const eebService = require('../eventBusService').abstract;

const app = require('../../app/home');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');
const global = require('../../global');

const collectionCampanhas = firestoreDAL.campanhas();
const collectionCampanhasInfluencers = firestoreDAL.campanhasInfluencers();
const collectionCampanhasSorteios = firestoreDAL.campanhasSorteios();
const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

const collectionFrontTemplates = firestoreDAL.frontTemplates();
const collectionInfluencers = firestoreDAL.influencers();
const collectionAppLinks = firestoreDAL.appLinks();

const collectionFaq = firestoreDAL.faq();

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

            const version = global.generateRandomId(7);

            const result = {
                success: true,
                host: this.parm.host
            };

            let saveLink;

            if (!idTemplate) throw new Error(`idTemplate inválido. Informe idTemplate`);
            if (!idInfluencer) throw new Error(`idInfluencer inválido. Informe idInfluencer`);
            if (!idCampanha) throw new Error(`idCampanha inválido. Informe idCampanha`);

            // Carga dos dados
            const promises = [
                collectionFrontTemplates.getDoc(idTemplate),
                collectionInfluencers.getDoc(idInfluencer),
                collectionCampanhas.getDoc(idCampanha),
                collectionCampanhasInfluencers.get({
                    filter: [
                        { field: "idCampanha", condition: "==", value: idCampanha },
                        { field: "idInfluencer", condition: "==", value: idInfluencer }
                    ]
                }),
                collectionCampanhasSorteios.get({
                    filter: [
                        { field: "idCampanha", condition: "==", value: idCampanha },
                    ]
                }),
                collectionCampanhasSorteiosPremios.get({
                    filter: [
                        { field: "idCampanha", condition: "==", value: idCampanha },
                    ]
                }),
                collectionFaq.get()
            ];

            return Promise.all(promises)
                .then(promisesResult => {
                    result.template = promisesResult[0];
                    result.influencer = promisesResult[1];
                    result.campanha = promisesResult[2];
                    result.campanhaInfluencer = promisesResult[3];
                    result.campanhaSorteios = promisesResult[4];
                    result.campanhaSorteiosPremios = promisesResult[5];
                    result.faq = promisesResult[6];

                    if (!result.template) throw new Error('Template not found');
                    if (!result.influencer) throw new Error('Influencer not found');
                    if (!result.campanha) throw new Error('Campanha not found');
                    if (!result.campanhaInfluencer || result.campanhaInfluencer.length === 0) throw new Error('Influencer da Campanha not found');
                    if (!result.campanhaSorteios || result.campanhaSorteios.length === 0) throw new Error('Sorteios da Campanha not found');
                    if (!result.campanhaSorteiosPremios || result.campanhaSorteiosPremios === 0) throw new Error('Premios da not found');

                    result.version = version;

                    return loadTemplateFiles(result.template);
                })

                .then(files => {
                    result.template.files = files;

                    return compileAndSendToStorage(result);
                })

                .then(sendResult => {
                    result.sendResult = sendResult;

                    saveLink = {
                        idTemplate: result.template.id,
                        idInfluencer: result.influencer.id,
                        idCampanha: result.campanha.id,
                        link: `/app/${result.influencer.id}/${result.campanha.id}`,
                        version: version,
                        empresas_reference: collectionInfluencers.getReference(result.influencer.id),
                        campanhas_reference: collectionCampanhas.getReference(result.campanha.id),
                        keywords: global.generateKeywords(
                            result.influencer.nome,
                            result.influencer.nomeExibicao,
                            result.influencer.email,
                            result.influencer.celular,
                            result.campanha.titulo,
                            result.campanha.url
                        )
                    };

                    global.setDateTime(saveLink, 'dtInclusao');

                    return collectionAppLinks.get({
                        filter: {
                            idTemplate: saveLink.idTemplate,
                            idInfluencer: saveLink.idInfluencer,
                            idCampanha: saveLink.idCampanha
                        },
                        limit: 1
                    });
                })

                .then(resultAppLinks => {
                    return collectionAppLinks.insertUpdate(
                        resultAppLinks.length ? resultAppLinks[0].id : null,
                        saveLink
                    )
                })

                .then(_ => {
                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })
    }

}

const compileAndSendToStorage = (data) => {
    return new Promise((resolve, reject) => {
        const storagePath = `app/${data.influencer.id}/${data.campanha.id}`;

        const promises = [];

        data.template.files.forEach(file => {
            promises.push(compileAndSaveContentOnStorage(storagePath, file, data));
        })

        return Promise.all(promises)

            .then(saveFilesResults => {
                return resolve(
                    saveFilesResults.map(f => {
                        return {
                            bucket: f.bucket.name,
                            file: {
                                name: f.file.name,
                                size: f.file.metadata.size,
                                md5Hash: f.file.metadata.md5Hash
                            }
                        }
                    })
                );
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const compileAndSaveContentOnStorage = (storagePath, file, obj) => {
    return new Promise((resolve, reject) => {
        const storageDest = `${storagePath}/${path.basename(file.name)}`;

        const fileOptions = {
            uploadType: { resumable: false },
            contentType: global.getContentTypeByExtension(storageDest)
        };

        app.compileApp(file.content, obj)

            .then(compiledData => {
                const bucket = admin.storage().bucket(obj.template.bucket);
                const storageFile = bucket.file(storageDest, fileOptions);

                storageFile.save(compiledData, e => {
                    if (e) {
                        console.error(e);
                        return reject(e);
                    } else {
                        return resolve(
                            {
                                bucket: bucket,
                                file: storageFile
                            }
                        );
                    }
                });
            })

            .catch(e => {
                return reject(e);
            })

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
