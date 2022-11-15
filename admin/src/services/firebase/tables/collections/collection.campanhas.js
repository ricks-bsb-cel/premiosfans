'use strict';

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        const getById = id => {
            return $q((resolve, reject) => {

                return appFirestoreHelper.getDoc(attr.collection, id)
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

            })
        }

        const save = campanha => {

            return $q((resolve, reject) => {

                // Não modifique o objeto que está no AngularJS...
                let toSave = { ...campanha };

                toSave = sanitizeCampanha(toSave);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(function (e) {
                        appErrors.showError(e);
                        return reject(e);
                    })

            })

        }

        const sanitizeCampanha = campanha => {

            campanha.influencers = campanha.influencers
                .map(i => {
                    return {
                        idInfluencer: i.idInfluencer
                    }
                });

            campanha.sorteios = campanha.sorteios.map(s => {
                return {
                    ativo: s.ativo,
                    dtSorteio: s.dtSorteio,
                    dtSorteio_timestamp: s.dtSorteio_timestamp,
                    dtSorteio_weak_day: s.dtSorteio_weak_day,
                    dtSorteio_yyyymmdd: s.dtSorteio_yyyymmdd,
                    guidSorteio: s.guidSorteio || globalFactory.guid(),
                    premios: s.premios.map(p => {
                        return {
                            guidPremio: p.guidPremio || globalFactory.guid(),
                            descricao: p.descricao,
                            valor: p.valor
                        };
                    })
                };
            })

            campanha.images = (campanha.images || [])
                .map(i => {
                    delete i.$$hashKey;
                    delete i.created_at;
                    delete i.featured;

                    return i;
                })

            if (campanha.id === 'new') {
                campanha.uidInclusao = appAuthHelper.profile.user.uid;
                campanha.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            campanha.uidAlteracao = appAuthHelper.profile.user.uid;
            campanha.dtAlteracao = appFirestoreHelper.currentTimestamp();

            campanha.keywords = globalFactory.generateKeywords(campanha.titulo, campanha.dtSorteio_ddmmyyyy, campanha.url);

            return campanha;
        }

        return {
            collection: firebaseCollection,
            getById: getById,
            save: save
        };

    });


export default ngModule;
