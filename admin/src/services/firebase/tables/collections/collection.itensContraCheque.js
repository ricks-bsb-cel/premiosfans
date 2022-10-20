'use strict';

const ngModule = angular.module('collection.itens-contracheque', [])

    .factory('collectionItensContraCheque', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper,
        $q
    ) {

        const attr = {
            collection: 'itensContraCheque',
            autoStartSnapshot: true,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const newItem = tipo => {
            return $q((resolve, reject) => {

                appAuthHelper.ready()

                    .then(_ => {
                        let doc = {
                            idEmpresa: appAuthHelper.profile.user.idEmpresa,
                            tipo: tipo,
                            ativo: false,
                            dtInclusao: appFirestoreHelper.currentTimestamp()
                        }

                        return firebaseCollection.addOrUpdateDoc('new', doc);
                    })

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(e => {
                        appErrors.showError(e, attr.collection);
                        return reject(e);
                    })

            })
        }

        return {
            collection: firebaseCollection,
            newItem: newItem
        };

    });

export default ngModule;
