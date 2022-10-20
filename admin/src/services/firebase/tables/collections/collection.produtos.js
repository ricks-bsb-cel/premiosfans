'use strict';

const ngModule = angular.module('collection.produtos', [])

    .factory('collectionProdutos', function (
        appErrors,
        appFirestoreHelper,
        appAuthHelper,
        appCollection,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'produtos',
            autoStartSnapshot: false,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getById = id => {
            return appFirestoreHelper.getDoc(attr.collection, id);
        }

        const save = function (data) {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        var update = {
                            idEmpresa: appAuthHelper.profile.user.idEmpresa,
                            nome: data.nome,
                            descricao: data.descricao || null,
                            codigo: data.codigo || null,
                            valor: data.valor,
                            ativo: typeof data.ativo === 'boolean' ? data.ativo : true,
                            idUser: appAuthHelper.profile.user.uid,
                            dtAlteracao: appFirestoreHelper.currentTimestamp(),
                            keywords: globalFactory.generateKeywords(data.nome, data.codigo)
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
            save: save,
            getById: getById
        };

    });


export default ngModule;
