'use strict';

import { update } from "lodash";

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q,

        collectionCampanhasInfluencers,
        collectionCampanhasSorteios,
        collectionCampanhasSorteiosPremios
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        const get = idCampanha => {
            return $q((resolve, reject) => {

                const promises = [
                    appFirestoreHelper.getDoc(attr.collection, idCampanha),
                    collectionCampanhasInfluencers.get(idCampanha),
                    collectionCampanhasSorteios.get(idCampanha),
                    collectionCampanhasSorteiosPremios.get(idCampanha)
                ];

                return Promise.all(promises)

                    .then(promisesResult => {
                        let campanha = promisesResult[0],
                            influencers = promisesResult[1],
                            sorteios = promisesResult[2],
                            premios = promisesResult[3];

                        campanha.influencers = influencers;
                        campanha.sorteios = globalFactory.sortArray(sorteios, 'dtSorteio_yyyymmdd');

                        campanha.sorteios = campanha.sorteios.map(s => {
                            s.premios = premios.filter(f => { return f.idSorteio === s.id; });
                            s.premios = globalFactory.sortArray(s.premios, 'pos');

                            return s;
                        });

                        return resolve(campanha);
                    })

                    .catch(e => {
                        return reject(e);
                    })

            })
        }

        const save = campanha => {

            return $q((resolve, reject) => {

                // Não modifique o objeto que está no AngularJS...
                let result = {},
                    toSave = { ...campanha };

                toSave = sanitize(toSave);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(campanhaSaved => {

                        result.campanha = campanhaSaved;

                        // Salva os influencers
                        return collectionCampanhasInfluencers.save(result.campanha, campanha.influencers);
                    })

                    .then(dadosInfluencers => {
                        result.influencers = dadosInfluencers;

                        return collectionCampanhasSorteios.save(result.campanha, campanha.sorteios);
                    })

                    .then(dadosSorteios => {
                        result.sorteios = dadosSorteios;

                        return removeSorteios(result.campanha);
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

        const sanitize = campanha => {

            const updateHash = globalFactory.generateRandomId(16);

            console.info(updateHash);

            let result = {
                id: campanha.id || 'new',
                ativo: typeof campanha.ativo === 'function' ? campanha.ativo : false,
                guidCampanha: campanha.guidCampanha || globalFactory.guid(),
                titulo: campanha.titulo,
                subTitulo: campanha.subTitulo || null,
                detalhe: campanha.detalhe || null,
                template: campanha.template,
                url: campanha.url,
                updateHash: updateHash
            };

            if (campanha.images && campanha.images.length) {
                result.images = campanha.images
                    .map(i => {
                        delete i.$$hashKey;
                        delete i.created_at;
                        delete i.featured;

                        return i;
                    })
            }

            if (result.id === 'new') {
                result.uidInclusao = appAuthHelper.profile.user.uid;
                result.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            result.uidAlteracao = appAuthHelper.profile.user.uid;
            result.dtAlteracao = appFirestoreHelper.currentTimestamp();

            result.keywords = globalFactory.generateKeywords(result.titulo, result.detalhe, result.url);

            return result;
        }

        const removeSorteios = campanha => {
            // Remove os sorteios que não tem o hash do último update
            return $q((resolve, reject) => {

                let query = [
                    { field: "idCampanha", operator: "==", value: campanha.id },
                    { field: "ativo", operator: "==", value: false },
                    { field: "updateHash", operator: "!=", value: campanha.updateHash }
                ];

                return collectionCampanhasSorteios.collection.query(query)
                    .then(toDelete => {
                        let promises = [];

                        toDelete.forEach(doc => {
                            promises.push(collectionCampanhasSorteios.collection.removeDoc(doc.id));
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


        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
