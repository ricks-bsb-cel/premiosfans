'use strict';

const ngModule = angular.module('collection.zoeAccount', [])

    .factory('collectionZoeAccounts', function (
        appCollection
    ) {

        const attr = {
            collection: 'zoeAccount',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);


        return {
            collection: firebaseCollection
        };

    });

export default ngModule;
