'use strict';

const ngModule = angular.module('collection.admConfigPath', [])

    .factory('collectionAdmConfigPath', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper,
        $q
    ) {

        const firebaseCollection = new appCollection({
            collection: 'admConfigPath',
            autoStartSnapshot: true,
            orderBy: 'label'
        });

        const save = function (data) {
            return $q((resolve, reject) => {
                var id = data.id || 'new';
                var update = angular.copy(data);

                delete update.id;
                delete update.key;

                update.idUser = appAuthHelper.user.uid;
                update.dtAlteracao = appFirestoreHelper.currentTimestamp();
                update.superUserOnly = typeof update.superUserOnly === 'boolean' ? update.superUserOnly : false;

                firebaseCollection
                    .addOrUpdateDoc(id, update)
                    .then(data => {
                        return resolve(data);
                    })
                    .catch(e => {
                        return reject(e);
                    })
            })
        }

        const getByHref = href => {
            return $q((resolve, reject) => {
                firebaseCollection.query(`href == ${href}`)
                    .then(queryResult => {
                        return resolve(queryResult.length ? queryResult[0] : null);
                    })
                    .catch(e => {
                        return reject(e);
                    })
            })
        }

        const getById = id => {
            return appFirestoreHelper.getDoc('admConfigPath', id);
        }

        return {
            collection: firebaseCollection,
            save: save,
            getByHref: getByHref,
            getById: getById
        };

    });

export default ngModule;
