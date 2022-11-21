'use strict';

const ngModule = angular.module('collection.titulos', [])

    .factory('collectionTitulos', function (
        appCollection
    ) {

        const attr = {
            collection: 'titulos',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
