"use strict";

const admin = require('firebase-admin');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanha = firestoreDAL.campanhas();
const collectionCampanhaInfluencers = firestoreDAL.campanhasInfluencers();
const collectionCampanhaSorteios = firestoreDAL.campanhasSorteios();
const collectionCampanhaSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();
const collectionTitulos = firestoreDAL.titulos();
const collectionTitulosCompras = firestoreDAL.titulosCompras();
const collectionTitulosPremios = firestoreDAL.titulosPremios();
const collectionLinks = firestoreDAL.appLinks();

const schema = _ => {
    const schema = Joi.object({
        idCampanha: Joi.string().token().min(18).max(22).required(),
        guidCampanha: Joi.string().required()
    });

    return schema;
}

const deleteDoc = (collectionName, id) => {
    return new Promise((resolve, reject) => {
        const doc = admin.firestore().collection(collectionName).doc(id);

        doc.delete()
            .then(_ => {
                return resolve();
            })

            .catch(e => {
                return reject(e);
            })

    })
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                host: this.parm.host,
                data: {},
                deleted: {}
            };
            let promise = [];

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.data = {
                        ...result.data,
                        ...dataResult
                    };

                    result.data.numerosDaSortePath = `/numerosDaSorte/${result.data.idCampanha}`;

                    return admin.database().ref(result.data.numerosDaSortePath).remove();
                })

                .then(_ => {
                    return collectionCampanha.getDoc(result.data.idCampanha);
                })

                .then(resultCampanha => {
                    result.data.campanha = resultCampanha;

                    if (result.data.guidCampanha !== 'ignore' && result.data.campanha.guidCampanha !== result.data.guidCampanha) {
                        throw new Error(`guidCampanha mismatch`);
                    }

                    // Busca todos os dados que serão removidos
                    const promise = [
                        collectionCampanhaInfluencers.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionCampanhaSorteios.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionCampanhaSorteiosPremios.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionTitulos.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionTitulosCompras.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionTitulosPremios.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] }),
                        collectionLinks.get({ filter: [{ field: "idCampanha", condition: "==", value: result.data.idCampanha }] })
                    ];

                    return Promise.all(promise);
                })

                .then(promiseResult => {
                    result.data.campanhaInfluencers = promiseResult[0];
                    result.data.campanhaSorteios = promiseResult[1];
                    result.data.campanhaSorteioPremios = promiseResult[2];
                    result.data.titulos = promiseResult[3];
                    result.data.titulosCompras = promiseResult[4];
                    result.data.titulosPremios = promiseResult[5];
                    result.data.appLinks = promiseResult[6];

                    return deleteDoc('campanhas', result.data.campanha.id);
                })

                .then(_ => {
                    result.deleted.campanhas = 1;

                    promise = [];

                    result.data.campanhaInfluencers.forEach(doc => {
                        promise.push(deleteDoc('campanhasInfluencers', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseCampanhainfluencers => {
                    result.deleted.campanhasInfluencers = resultPromiseCampanhainfluencers.length;

                    promise = [];

                    result.data.campanhaSorteios.forEach(doc => {
                        promise.push(deleteDoc('campanhasSorteios', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseCampanhaSorteios => {
                    result.deleted.campanhasSorteios = resultPromiseCampanhaSorteios.length;

                    promise = [];

                    result.data.campanhaSorteioPremios.forEach(doc => {
                        promise.push(deleteDoc('campanhasSorteiosPremios', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseCampanhasSorteiosPremios => {
                    result.deleted.campanhasSorteiosPremios = resultPromiseCampanhasSorteiosPremios.length;

                    promise = [];

                    result.data.titulos.forEach(doc => {
                        promise.push(deleteDoc('titulos', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseTitulos => {
                    result.deleted.titulos = resultPromiseTitulos.length;

                    promise = [];

                    result.data.titulosCompras.forEach(doc => {
                        promise.push(deleteDoc('titulosCompras', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseTitulosCompras => {
                    result.deleted.titulosCompras = resultPromiseTitulosCompras.length;

                    promise = [];

                    result.data.titulosPremios.forEach(doc => {
                        promise.push(deleteDoc('titulosPremios', doc.id));
                    });

                    return Promise.all(promise);
                })

                .then(resultPromiseTitulosPremios => {
                    result.deleted.titulosPremios = resultPromiseTitulosPremios.length;

                    promise = [];

                    result.data.appLinks.forEach(doc => {
                        promise.push(deleteDoc('appLinks', doc.id));
                    });

                    return Promise.all(promise);
                })
                .then(resultPromiseAppLinks => {
                    result.deleted.appLinks = resultPromiseAppLinks.length;

                    delete result.data;

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

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    if (!data.idCampanha) {
        throw new Error('invalid parm');
    }

    const service = new Service(request, response, {
        name: 'purge-campanha',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.superUser
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {

    if (!request.body) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(request.body, request, response);
}
