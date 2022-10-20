'use strict';

const ngModule = angular.module('collection.planos', [])

    .factory('collectionPlanos', function (
        appErrors,
        appFirestoreHelper,
        appAuthHelper,
        appCollection,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'planos',
            autoStartSnapshot: true,
            filterEmpresa: true
        };
        
        var firebaseCollection = new appCollection(attr);

        var save = function (data) {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        var update = {
                            idEmpresa: appAuthHelper.profile.user.idEmpresa,
                            nome: data.nome,
                            sigla: data.sigla || null,
                            valorMinimo: data.valorMinimo,
                            valorMaximo: data.valorMaximo,
                            msgBoleto: data.msgBoleto || null,
                            ativo: typeof data.ativo === 'boolean' ? data.ativo : true,
                            idUser: appAuthHelper.profile.user.uid,
                            dtAlteracao: appFirestoreHelper.currentTimestamp(),
                            keywords: globalFactory.generateKeywords(data.nome, data.sigla)
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
