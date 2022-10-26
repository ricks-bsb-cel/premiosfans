'use strict';

const ngModule = angular.module('collection.empresas', [])

    .factory('collectionEmpresas', function (
        $q,
        appAuthHelper,
        appFirestoreHelper,
        appCollection,
        globalFactory
    ) {

        const attr = {
            collection: 'empresas',
            autoStartSnapshot: false
        };

        const firebaseCollection = new appCollection(attr);

        const save = data => {

            return $q((resolve, reject) => {

                let update = null, id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        update = {
                            ...data,
                            keywords: globalFactory.generateKeywords(data.nome, data.cpfcnpj, data.celular, data.email, data.url)
                        };

                        if (id === 'new') update.dtInclusao = appFirestoreHelper.currentTimestamp();

                        return firebaseCollection.addOrUpdateDoc(id, update);
                    })

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(e => {
                        console.error(e);
                        return reject(e);
                    })

            })

        }

        return {
            collection: firebaseCollection,
            save: save
        };

    });


export default ngModule;
