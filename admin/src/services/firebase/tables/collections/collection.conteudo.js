'use strict';

const ngModule = angular.module('collection.conteudo', [])

    .factory('collectionConteudo', function (
        appErrors,
        appFirestoreHelper,
        appAuthHelper,
        appCollection,
        utilsService,
        $q
    ) {

        const attr = {
            collection: 'conteudo',
            autoStartSnapshot: true,
            filterEmpresa: false,
            orderBy: 'sigla'
        };

        var firebaseCollection = new appCollection(attr);

        var save = function (data) {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        var update = {
                            sigla: data.sigla,
                            descricao: data.descricao,
                            html: data.html,
                            publico: typeof data.publico === 'boolean' ? data.publico : false,
                            dtAlteracao: appFirestoreHelper.currentTimestamp()
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
                        appErrors.showError(e, attr.collection);
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
