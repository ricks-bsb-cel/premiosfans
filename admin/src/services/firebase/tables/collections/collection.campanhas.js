'use strict';

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        URLs,
        $http,
        $q
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getById = id => {
            return appFirestoreHelper.getDoc(attr.collection, id);
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
                        descricao: p.descricao,
                        valor: parseFloat(p.valor)
                    }
                });

            if (campanha.id === 'new') {
                campanha.uidInclusao = appAuthHelper.profile.user.uid;
                campanha.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            campanha.uidAlteracao = appAuthHelper.profile.user.uid;
            campanha.dtAlteracao = appFirestoreHelper.currentTimestamp();

            return campanha;
        }

        return {
            collection: firebaseCollection,
            getById: getById,
            save: save
        };

    });


export default ngModule;
