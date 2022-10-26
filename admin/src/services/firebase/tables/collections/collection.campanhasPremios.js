'use strict';

const ngModule = angular.module('collection.campanhasPremios', [])

    .factory('collectionCampanhasPremios', function (
        appCollection,
        appAuthHelper,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'campanhasPremios',
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getPremiosCampanha = (idCampanha) => {
            return $q((resolve, reject) => {

                let produtosContrato,
                    idProdutos = [];

                return appAuthHelper.ready()

                    .then(_ => {

                        return firebaseCollection.query([
                            { field: "idCampanha", operator: "==", value: idCampanha }
                        ]);

                    })

                    .then(resultCampanhasProdutos => {
                        produtosContrato = resultCampanhasProdutos;

                        produtosContrato = globalFactory.sortArray(produtosContrato, 'pos');

                        return resolve(produtosContrato);
                    })

                    .catch(e => {
                        return reject(e);
                    })
            })
        }

        return {
            collection: firebaseCollection,
            getPremiosCampanha: getPremiosCampanha
        };
    })

export default ngModule;
