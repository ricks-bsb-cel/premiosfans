'use strict';

const ngModule = angular.module('collection.cartosAccounts', [])

    .factory('collectionCartosAccounts', function (
        appCollection
    ) {

        const attr = {
            collection: 'cartosAccounts',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
