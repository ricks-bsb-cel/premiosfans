'use strict';

const ngModule = angular.module('collection.transacoes', [])

    .factory('collectionTransacoes', function (
        appCollection
    ) {

        const attr = {
            collection: 'contasTransactions',
            autoStartSnapshot: false,
            filterEmpresa: true
        };
        
        var firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
