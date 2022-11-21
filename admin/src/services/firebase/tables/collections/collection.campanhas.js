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

                        if (!sorteios || sorteios.length === 0) {
                            sorteios.push({
                                ativo: false,
                                idCampanha: campanha.id,
                                guidSorteio: globalFactory.guid(),
                                deleted: false,
                                premios: []
                            })
                        }

                        campanha.influencers = influencers;
                        campanha.sorteios = globalFactory.sortArray(sorteios, 'dtSorteio_yyyymmdd');

                        campanha.qtdGrupos = campanha.qtdGrupos || 100;
                        campanha.qtdNumerosPorGrupo = campanha.qtdNumerosPorGrupo || 1000;

                        campanha.sorteios = campanha.sorteios.map(s => {
                            s.premios = premios
                                .filter(f => {
                                    return f.idSorteio === s.id;
                                })
                                .map(p => {
                                    p.deleted = false;
                                    return p;
                                });

                            s.premios = globalFactory.sortArray(s.premios, 'pos');
                            s.deleted = false;

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

                        return removeDeletedSorteios(campanha);
                    })

                    .then(_ => {
                        return resolve(result);
                    })


                    .catch(function (e) {
                        console.error(e);

                        return reject(e);
                    })

            })
        }

        const sanitize = campanha => {

            if (!campanha.titulo) throw new Error(`O nome da campanha é obrigatório`);
            if (!campanha.url) throw new Error(`A URL da campanha é obrigatório`);
            if (!campanha.template) throw new Error(`O Template da campanha é obrigatório`);
            if (!campanha.vlTitulo) throw new Error(`O Valor do Título é obrigatório`);
            if (!campanha.qtdNumerosDaSortePorTitulo) throw new Error(`A quantidade de números da sorte por título é obrigatório`);

            let result = {
                id: campanha.id || 'new',
                ativo: typeof campanha.ativo === 'function' ? campanha.ativo : false,
                guidCampanha: campanha.guidCampanha || globalFactory.guid(),
                titulo: campanha.titulo,
                subTitulo: campanha.subTitulo || null,
                detalhe: campanha.detalhe || null,
                template: campanha.template,
                url: campanha.url,
                vlTitulo: campanha.vlTitulo,
                qtdNumerosDaSortePorTitulo: campanha.qtdNumerosDaSortePorTitulo,
                qtdSorteios: 0,
                qtdPremios: 0,
                vlTotal: 0,
                qtdGrupos: campanha.qtdGrupos,
                qtdNumerosPorGrupo: campanha.qtdNumerosPorGrupo
            };

            campanha.sorteios.forEach(s => {
                result.qtdSorteios++;
                s.premios.forEach(p => {
                    result.qtdPremios++;
                    result.vlTotal = (parseFloat(result.vlTotal) + parseFloat(p.valor)).toFixed(2)
                })
            })

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

        const removeDeletedSorteios = campanha => {
            // Remove os sorteios quer foram excluídos pelo usuário
            return $q((resolve, reject) => {

                let promises = [];

                campanha.sorteios
                    .filter(f => {
                        return !f.ativo && f.deleted && f.id !== 'new';
                    })
                    .forEach(s => {
                        promises.push(collectionCampanhasSorteios.collection.removeDoc(s.id));
                    });

                return Promise.all(promises)

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
