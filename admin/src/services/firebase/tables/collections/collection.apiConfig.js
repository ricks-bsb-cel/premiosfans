'use strict';

const ngModule = angular.module('collection.api-config', [])

    .factory('collectionApiConfig', function (
        $http,
        URLs,
        appErrors,
        appAuthHelper,
        appCollection,
        alertFactory,
        blockUiFactory,
        $q
    ) {

        var firebaseCollection = new appCollection({
            collection: 'apiConfig',
            autoStartSnapshot: true,
            filterEmpresa: false
        });

        const save = data => {
            return $q((resolve, reject) => {

                blockUiFactory.start();

                appAuthHelper.ready()

                    .then(_ => {

                        return $http({
                            url: URLs.apiConfig + (data.id ? '/' + data.id : ''),
                            method: 'post',
                            data: {
                                idEmpresa: data.idEmpresa,
                                descricao: data.descricao,
                                ativo: data.ativo,
                                sandbox: data.sandbox,
                                gatewayOnly: data.gatewayOnly
                            },
                            headers: {
                                token: appAuthHelper.token
                            }
                        });

                    })

                    .then(
                        function (response) {
                            blockUiFactory.stop();
                            return resolve(response.data.data);
                        },
                        function (e) {
                            blockUiFactory.stop();
                            appErrors.showError(e);
                            return reject(e);
                        }
                    )

                    .catch(function (e) {
                        blockUiFactory.stop();
                        appErrors.showError(e);
                        return reject(e);
                    })

                /*
                var apiKey = data.id || null;
 
                appAuthHelper.ready()
 
                    .then(_ => {
 
                        update = {
                            idEmpresa: data.idEmpresa,
                            idEmpresa_reference: appFirestoreHelper.doc('empresas', data.idEmpresa),
                            descricao: data.descricao,
                            ativo: typeof data.ativo === 'boolean' ? data.ativo : true,
                            dtAlteracao: appFirestoreHelper.currentTimestamp(),
                            idUser: appAuthHelper.profile.uid,
                            publicKey: data.publicKey || null,
                            privateKey: data.privateKey || null
                        };
 
                        if (!apiKey) {
                            update.dtInclusao = appFirestoreHelper.currentTimestamp();
                            update.publicKey = globalFactory.generateRandomId(20);
                            update.privateKey = globalFactory.generateRandomId(20);
                        }
 
                        return sha256(`${update.idEmpresa}-${update.publicKey}-${update.privateKey}`);
 
                    })
 
                    .then(sha256Result => {
 
                        if (!apiKey) {
                            apiKey = `${update.idEmpresa}-${update.publicKey}-${sha256Result}`;
                        } else {
                            if (apiKey !== `${update.idEmpresa}-${update.publicKey}-${sha256Result}`) {
                                throw new Error('sha256 error. New/old key mismatch!');
                            }
                        }
 
                        return firebaseCollection.addOrUpdateDoc(apiKey, update);
                    })
 
                    .then(dataResult => {
 
                        data = dataResult;
 
                        const path = `/apiConfig/${apiKey}`;
 
                        return appDatabaseHelper.set(path, {
                            ativo: update.ativo,
                            privateKey: update.privateKey,
                            idEmpresa: update.idEmpresa
                        })
 
                    })
 
                    .then(_ => {
                        return resolve(data);
                    })
 
                    .catch(function (e) {
                        appErrors.showError(e);
                        return reject(e);
                    })
 
                */

            })
        }

        const remove = data => {
            alertFactory.yesno('O registro será removido e não poderá ser recuperado.').then(_ => {
                firebaseCollection.removeDoc(data.id);
            })
        }

        return {
            collection: firebaseCollection,
            save: save,
            remove: remove
        };

    });


export default ngModule;
