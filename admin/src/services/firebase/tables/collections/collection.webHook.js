'use strict';

const ngModule = angular.module('collection.webhook', [])

    .factory('collectionWebhook', function (
        firebaseBaseCollection
    ) {

        var firebaseCollection = new firebaseBaseCollection('_webHookReceived');

        return {
            collection: firebaseCollection
        };

    });


export default ngModule;
