'use strict';

const ngModule = angular.module('collection.chavesPix', [])

    .factory('collectionChavesPix', function (
        appCollection
    ) {

        const attr = {
            collection: 'contasPixKeys',
            autoStartSnapshot: true,
            filterEmpresa: true
        };
        
        var firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
