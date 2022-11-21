'use strict';

const ngModule = angular.module('collection.titulosCompras', [])

    .factory('collectionTitulosCompras', function (
        appCollection
    ) {

        const attr = {
            collection: 'titulosCompras',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
