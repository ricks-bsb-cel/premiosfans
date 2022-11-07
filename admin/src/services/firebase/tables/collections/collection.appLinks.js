'use strict';

const ngModule = angular.module('collection.app-links', [])

    .factory('collectionAppLinks', function (
        appCollection
    ) {

        const attr = {
            collection: 'appLinks',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
