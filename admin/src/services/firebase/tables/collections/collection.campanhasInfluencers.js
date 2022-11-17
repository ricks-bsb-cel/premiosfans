'use strict';

const ngModule = angular.module('collection.campanhasInfluencers', [])

    .factory('collectionCampanhasInfluencers', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper,
        $q
    ) {

        const attr = {
            collection: 'campanhasInfluencers',
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

        const saveList = (campanha, influencers) => {
            return $q((resolve, reject) => {

                let promises = [];

                influencers.forEach(i => {
                    promises.push(save(campanha, i));
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

        const save = (campanha, influencer) => {

            if (Array.isArray(influencer)) return saveList(campanha, influencer);

            return $q((resolve, reject) => {

                let toSave = { ...influencer };

                toSave = sanitize(campanha, toSave);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(function (e) {
                        console.error(e);

                        return reject(e);
                    })

            })
        }

        const sanitize = (campanha, influencer) => {
            let result = {
                id: influencer.id || 'new',
                idCampanha: campanha.id,
                idInfluencer: influencer.idInfluencer,
                selected: typeof influencer.selected === 'boolean' ? influencer.selected : false
            };

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
    })

export default ngModule;
