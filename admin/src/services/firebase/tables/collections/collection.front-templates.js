'use strict';

const ngModule = angular.module('collection.front-templates', [])

    .factory('collectionFrontTemplates', function (
        appCollection
    ) {

        const attr = {
            collection: 'frontTemplates',
            autoStartSnapshot: false,
            filterEmpresa: false
        };
        
        var firebaseCollection = new appCollection(attr);

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
