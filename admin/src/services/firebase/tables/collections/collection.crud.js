'use strict';

const ngModule = angular.module('collection.crud', [])

    .factory('collectionCrud', function (
        appErrors,
        appFirestoreHelper,
        appAuthHelper,
        appCollection,
        alertFactory,
        $q
    ) {

        var firebaseCollection = new appCollection({
            collection: '_crud',
            autoStartSnapshot: true,
            filterEmpresa: true
        });

        const save = data => {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        var update = {
                            idEmpresa: appAuthHelper.profile.user.idEmpresa,
                            descricao: data.descricao,
                            ativo: typeof data.ativo === 'boolean' ? data.ativo : true,
                            situacao: data.situacao || null,
                            dtAlteracao: appFirestoreHelper.currentTimestamp(),
                            idUser: appAuthHelper.user.uid
                        };

                        if (id === 'new') {
                            update.dtInclusao = appFirestoreHelper.currentTimestamp();
                        }

                        return firebaseCollection.addOrUpdateDoc(id, update);
                    })

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(function (e) {
                        appErrors.showError(e);
                        return reject(e);
                    })

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
