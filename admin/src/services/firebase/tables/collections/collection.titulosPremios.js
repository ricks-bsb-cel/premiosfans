'use strict';

const ngModule = angular.module('collection.titulosPremios', [])

    .factory('collectionTitulosPremios', function (
        appCollection
    ) {

        const attr = {
            collection: 'titulosPremios',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
