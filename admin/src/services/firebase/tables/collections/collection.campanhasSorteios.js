'use strict';

const ngModule = angular.module('collection.campanhasSorteios', [])

    .factory('collectionCampanhasSorteios', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q,

        collectionCampanhasSorteiosPremios
    ) {

        const attr = {
            collection: 'campanhasSorteios',
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        const get = idCampanha => {
            return $q((resolve, reject) => {

                return appAuthHelper.ready()

                    .then(_ => {

                        return firebaseCollection.query([
                            { field: "idCampanha", operator: "==", value: idCampanha }
                        ]);

                    })

                    .then(queryResult => {
                        return resolve(queryResult);
                    })

                    .catch(e => {
                        console.error(e);

                        return reject(e);
                    })
            })
        }

        const saveList = (campanha, sorteios) => {
            return $q((resolve, reject) => {

                let promises = [];

                sorteios.forEach(s => {
                    promises.push(save(campanha, s));
                })

                Promise.all(promises)
                    .then(promisesResult => {
                        return resolve(promisesResult);
                    })
                    .catch(e => {
                        console.error(e);

                        return reject();
                    })

            })
        }

        const save = (campanha, sorteio) => {

            if (Array.isArray(sorteio)) return saveList(campanha, sorteio);

            return $q((resolve, reject) => {

                // Não modifique o objeto que está no AngularJS...
                let result = {},
                    toSave = sanitize(campanha, sorteio);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(sorteioSaved => {
                        result.sorteio = sorteioSaved;

                        return collectionCampanhasSorteiosPremios.save(result.sorteio, sorteio.premios);
                    })

                    .then(premiosSaved => {
                        result.premios = premiosSaved;
                        
                        return removePremios(result.sorteio);
                    })

                    .then(_ => {
                        return resolve(result);
                    })

                    .catch(function (e) {
                        appErrors.showError(e);
                        return reject(e);
                    })

            })
        }

        const removePremios = sorteio => {
            // Remove os prêmios que não tem o hash do último update
            return $q((resolve, reject) => {

                let query = [
                    { field: "idCampanha", operator: "==", value: sorteio.idCampanha },
                    { field: "ativo", operator: "==", value: false },
                    { field: "updateHash", operator: "!=", value: sorteio.updateHash }
                ];

                return collectionCampanhasSorteiosPremios.collection.query(query)
                    .then(toDelete => {
                        let promises = [];

                        toDelete.forEach(doc => {
                            promises.push(collectionCampanhasSorteiosPremios.collection.removeDoc(doc.id));
                        })

                        return Promise.all(promises);
                    })

                    .then(_ => {
                        return resolve();
                    })

                    .catch(e => {
                        console.error(e);

                        return reject();
                    })
            })
        }

        const sanitize = (campanha, sorteio) => {

            let result = {
                id: sorteio.id || 'new',
                idCampanha: campanha.id,
                ativo: typeof sorteio.ativo === 'function' ? sorteio.ativo : false,
                dtSorteio: sorteio.dtSorteio,
                dtSorteio_timestamp: sorteio.dtSorteio_timestamp,
                dtSorteio_weak_day: sorteio.dtSorteio_weak_day,
                dtSorteio_yyyymmdd: sorteio.dtSorteio_yyyymmdd,
                guidSorteio: sorteio.guidSorteio || globalFactory.guid(),
                updateHash: campanha.updateHash,
                ativo: false
            }

            if (result.id === 'new') {
                result.uidInclusao = appAuthHelper.profile.user.uid;
                result.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            result.uidAlteracao = appAuthHelper.profile.user.uid;
            result.dtAlteracao = appFirestoreHelper.currentTimestamp();

            return result;
        }

        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
