'use strict';

const ngModule = angular.module('collection.lancamentos', [])

    .factory('collectionLancamentos', function (
        appFirestoreHelper,
        appCollection
    ) {

        const attr = {
            collection: 'lancamentos',
            autoStartSnapshot: false,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getById = id => {
            return appFirestoreHelper.getDoc(attr.collection, id);
        }

        return {
            collection: firebaseCollection,
            getById: getById
        };

    });


export default ngModule;
