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

                campanha = sanitizeCampanha(campanha);

                let id = campanha.id || 'new';

                delete campanha.id;

                firebaseCollection.addOrUpdateDoc(id, campanha)

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
                .filter(f => { return f.selected; })
                .map(i => {
                    return {
                        idInfluencer: i.idInfluencer
                    }
                });

            campanha.premios = campanha.premios
                .map(p => {
                    return {
                        guidPremio: p.guidPremio,
                        descricao: p.descricao || null,
                        valor: parseFloat(p.valor)
                    }
                });

            campanha.images = campanha.images
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
