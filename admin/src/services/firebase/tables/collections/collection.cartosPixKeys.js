'use strict';

const ngModule = angular.module('collection.cartosPixKeys', [])

    .factory('collectionCartosPixKeys', function (
        appCollection
    ) {

        const attr = {
            collection: 'cartosPixKeys',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
