'use strict';

const ngModule = angular.module('collection.contas', [])

    .factory('collectionContas', function (
        appCollection,
        appFirestoreHelper,
        $q
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        const get = idConta => {
            return $q((resolve, reject) => {

                return appFirestoreHelper.getDoc(attr.collection, idConta)

                    .then(contaResult => {
                        return resolve(contaResult);
                    })

                    .catch(e => {
                        return reject(e);
                    })

            })
        }

        const save = conta => {
            return $q((resolve, reject) => {

                // Não modifique o objeto que está no AngularJS...
                let result = {},
                    toSave = { ...conta };

                toSave = sanitize(toSave);

                let id = toSave.id || 'new';

                delete toSave.id;

                firebaseCollection.addOrUpdateDoc(id, toSave)

                    .then(contaSaved => {

                        result.conta = contaSaved;

                        return resolve(result);
                    })

                    .catch(function (e) {
                        console.error(e);

                        return reject(e);
                    })

            })
        }

        const sanitize = conta => {

            let result = {
                id: conta.id || 'new'
            };

            return result;
        }

        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
