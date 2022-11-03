"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;

const { Storage } = require('@google-cloud/storage');
const storage = new Storage();
/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');
const global = require('../../global');

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
                success: true,
                host: this.parm.host
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

                    if (!result.templates.length || !result.influencers.length || !result.campanhas.length) {
                        throw new Error(`Nenhum registro encontrado em uma ou mais coleções de dados`);
                    }

                    return loadTemplateFiles(result.templates);
                })

                .then(_ => {

                    // Aqui já temos os dados das campanhas, dos influencers e dos templates (inclusive, com conteúdo do arquivo)

                    let generations = [];

                    result.templates.forEach(template => {
                        result.influencers.forEach(influencer => {
                            result.campanhas.forEach(campanha => {
                                generations.push({
                                    template: { ...template },
                                    influencer: { ...influencer },
                                    campanha: { ...campanha }
                                })
                            })
                        })
                    })

                    // Dispara as gerações... uma por uma...

                    return resolve(result)
                })

                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })
    }

}

const generateAll = generations => {

}

const generate = (template, influencer, campanha) => {
    return new Promise((resolve, reject) => {

        const storagePath = `app/${influencer.id}/${campanha.id}/${template.nome}`;

        const obj = {
            influencer: influencer,
            campanha: campanha
        };

        let promises = [];

        template.files.forEach(file => {
            const storageDest = `${storagePath}/${file.nome}`;
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
                console.info(saveFilesResults);

                return resolve();
            })
            .catch(e => {
                return reject(e);
            })

    })
}

const saveContentOnStorage = (bucket, storageFile, content, idTemplate, idInfluencer, idCampanha) => {
    return new Promise((resolve, reject) => {

        const fileOptions = {
            uploadType: { resumable: false },
            contentType: global.getContentTypeByExtension(storageFile)
        };

        const bucket = admin.storage().bucket(bucket);
        const storageFile = bucket.file(storageFile, fileOptions);

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

const loadTemplateFiles = templates => { // Resposável por buscar os templates no Storage

    const getFiles = template => {
        return new Promise((resolve, reject) => {

            storage.bucket(template.bucket).getFiles({
                prefix: template.storagePathDev
            })

                .then(([files]) => {
                    template.files = files.map(f => {
                        return {
                            name: f.name,
                            file: f,
                            metadata: {
                                id: f.metadata.id,
                                size: f.metadata.size
                            }
                        };
                    });

                    let promises = [];

                    template.files.forEach(f => {
                        promises.push(getFileContent(f.file));
                    })

                    return Promise.all(promises);
                })

                .then(filesContent => {

                    filesContent.forEach((c, i) => {
                        template.files[i].content = c;

                        // Não preciso mais do objeto File
                        delete template.files[i].file;
                    })

                    return resolve();
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

    return new Promise((resolve, reject) => {

        let promises = [];

        templates.forEach(t => {
            promises.push(getFiles(t));
        })

        return Promise.all(promises)
            .then(_ => {
                return resolve();
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
            var Readable = require('stream').Readable;
            var stream = new Readable();
            stream.push(buffer);
            stream.push(null);
            return stream;
        }

        return file.download(function (e, contents) {
            if (!e) {
                var stream = bufferToStream(contents);
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
