'use strict';

const ngModule = angular.module('collection.funcionarios', [])

    .factory('collectionFuncionarios', function (
        appCollection
    ) {

        const attr = {
            collection: 'funcionarios',
            autoStartSnapshot: false,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });

export default ngModule;
