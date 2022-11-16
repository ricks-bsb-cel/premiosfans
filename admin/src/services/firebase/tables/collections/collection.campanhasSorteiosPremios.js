'use strict';

const ngModule = angular.module('collection.campanhas-sorteios-premios', [])

    .factory('collectionCampanhasSorteiosPremios', function (
        appCollection,
        appAuthHelper,
        globalFactory,
        appFirestoreHelper,
        $q
    ) {

        const attr = {
            collection: 'campanhasSorteiosPremios',
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const get = (idCampanha, idSorteio) => {
            return $q((resolve, reject) => {

                return appAuthHelper.ready()

                    .then(_ => {
                        let query = [
                            { field: "idCampanha", operator: "==", value: idCampanha }
                        ];

                        if (idSorteio) {
                            query.push({ field: "idSorteio", operator: "==", value: idSorteio });
                        }

                        return firebaseCollection.query(query);
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

        const sanitize = (sorteio, premio) => {
            let result = {
                id: premio.id || 'new',
                idCampanha: sorteio.idCampanha,
                idSorteio: sorteio.id,
                guidPremio: premio.guidPremio || globalFactory.guid(),
                descricao: premio.descricao,
                valor: premio.valor,
                updateHash: sorteio.updateHash,
                ativo: false,
                pos: premio.pos
            }

            if (result.id === 'new') {
                result.uidInclusao = appAuthHelper.profile.user.uid;
                result.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            result.uidAlteracao = appAuthHelper.profile.user.uid;
            result.dtAlteracao = appFirestoreHelper.currentTimestamp();

            result.keywords = globalFactory.generateKeywords(result.descricao);

            return result;
        }

        const saveList = (sorteio, premios) => {
            return $q((resolve, reject) => {

                let promises = [];

                premios.forEach((p, i) => {
                    p.pos = i + 1;

                    promises.push(save(sorteio, p));
                })

                Promise.all(promises)
                    .then(savedData => {
                        return resolve(savedData);
                    })
                    .catch(e => {
                        console.error(e);

                        return reject();
                    })

            })
        }

        const save = (sorteio, premio) => {

            if (Array.isArray(premio)) return saveList(sorteio, premio);

            return $q((resolve, reject) => {

                let result = {},
                    toSave = sanitize(sorteio, premio);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(updateResult => {
                        result.updateResult = updateResult;

                        return resolve(result);
                    })

                    .catch(function (e) {
                        console.error(e);

                        return reject(e);
                    })

            })
        }

        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };
    })

export default ngModule;
