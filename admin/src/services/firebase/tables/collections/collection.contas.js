'use strict';

const ngModule = angular.module('collection.contas', [])

    .factory('collectionContas', function (
        appCollection
    ) {

        const attr = {
            collection: 'contas',
            autoStartSnapshot: true,
            filterEmpresa: true
        };
        
        var firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
