'use strict';

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q,

        collectionEmpresas,
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
                    collectionEmpresas.get(),
                    collectionCampanhasInfluencers.get(idCampanha),
                    collectionCampanhasSorteios.get(idCampanha),
                    collectionCampanhasSorteiosPremios.get(idCampanha)
                ];

                return Promise.all(promises)

                    .then(promisesResult => {
                        let campanha = promisesResult[0],
                            empresas = promisesResult[1],
                            influencers = promisesResult[2],
                            sorteios = promisesResult[3],
                            premios = promisesResult[4];

                        campanha.influencers = influencers;
                        campanha.sorteios = sorteios;

                        campanha.sorteios = campanha.sorteios.map(s => {
                            s.premios = premios.filter(f => { return f.idSorteio === s.id; });

                            return s;
                        });

                        debugger;

                        return resolve(campanha);
                    })

                    .catch(e => {
                        return reject(e);
                    })


                /*
                return appFirestoreHelper.getDoc(attr.collection, idCampanha)
                    .then(campanha => {
                        campanha.influencers = campanha.influencers.map(influencer => {
                            const pos = appAuthHelper.profile.user.empresas.findIndex(f => {
                                return f.id === influencer.idInfluencer;
                            });

                            influencer.nome = pos < 0 ? '* Unauthorized *' : appAuthHelper.profile.user.empresas[pos].nome;
                            influencer.selected = true;

                            return influencer;
                        })

                        return resolve(campanha);
                    })
                    .catch(e => {
                        return reject(e);
                    })
                */

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

                        return resolve(result);
                    })

                    .catch(function (e) {
                        appErrors.showError(e);
                        return reject(e);
                    })

            })
        }

        const sanitize = campanha => {

            let result = {
                id: campanha.id || 'new',
                ativo: typeof campanha.ativo === 'function' ? campanha.ativo : false,
                guidCampanha: campanha.guidCampanha || globalFactory.guid(),
                titulo: campanha.titulo,
                subTitulo: campanha.subTitulo || null,
                detalhe: campanha.detalhe || null,
                template: campanha.template,
                url: campanha.url
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

        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
