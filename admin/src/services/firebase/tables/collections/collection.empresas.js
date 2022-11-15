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

        const get = _ => {
            return $q((resolve, reject) => {

                return appAuthHelper.ready()

                    .then(_ => {
                        return firebaseCollection.query();
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

                        update = sanitize(update);

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

        const sanitize = empresa => {
            empresa.images = empresa.images || [];

            empresa.images = empresa.images.map(i => {
                return {
                    bytes: i.bytes,
                    etag: i.etag,
                    original_extension: i.original_extension,
                    original_filename: i.original_filename,
                    public_id: i.public_id,
                    resource_type: i.resource_type,
                    secure_url: i.secure_url,
                    signature: i.signature,
                    url: i.url,
                    version: i.version,
                    version_id: i.version_id,
                    width: i.width,
                    version_id: i.version_id
                };
            });

            return empresa;
        }

        return {
            collection: firebaseCollection,
            save: save,
            get: get
        };

    });


export default ngModule;
