'use strict';

const ngModule = angular.module('collection.contas', [])

    .factory('collectionContas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'contas',
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

                let id = toSave.id || 'new';

                toSave.keywords = globalFactory.generateKeywords(
                    toSave.companyName,
                    toSave.companyRepresentative.name,
                    toSave.contact.email,
                    toSave.documentNumber
                );

                if (id === 'new') {
                    toSave.uidInclusao = appAuthHelper.user.uid;
                    globalFactory.setDateTime(toSave, 'dtInclusao');
                }

                toSave.uidAlteracao = appAuthHelper.user.uid;
                globalFactory.setDateTime(toSave, 'dtAlteracao');

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

        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
