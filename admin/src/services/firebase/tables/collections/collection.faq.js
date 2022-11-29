'use strict';

const ngModule = angular.module('collection.faq', [])

    .factory('collectionFaq', function (
        appErrors,
        globalFactory,
        appAuthHelper,
        appCollection,
        $q
    ) {

        const attr = {
            collection: 'faq',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        var save = function (data) {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        if (!data.pergunta || !data.resposta) throw new Error('Informe a pergunta e resposta');

                        let toSave = {
                            pergunta: data.pergunta || null,
                            resposta: data.resposta,
                        };

                        toSave.keywords = globalFactory.generateKeywords(
                            data.pergunta
                        );

                        if (id === 'new') {
                            toSave.uidInclusao = appAuthHelper.user.uid;
                            globalFactory.setDateTime(toSave, 'dtInclusao');
                        }

                        toSave.uidAlteracao = appAuthHelper.user.uid;
                        globalFactory.setDateTime(toSave, 'dtAlteracao');

                        delete toSave.id;

                        return firebaseCollection.addOrUpdateDoc(id, toSave);
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
