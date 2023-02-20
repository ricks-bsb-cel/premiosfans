'use strict';

const ngModule = angular.module('collection.cartosServiceUserCredentials', [])

    .factory('collectionCartosServiceUserCredentials', function (
        appCollection
    ) {

        const attr = {
            collection: 'serviceUserCredential',
            autoStartSnapshot: true,
            filterEmpresa: false,
            orderBy: 'cpf'
        };

        var firebaseCollection = new appCollection(attr);

        async function saveAlias(data) {
            const toSave = {
                alias: data.alias
            };

            return await firebaseCollection.updateDoc(data.id, toSave);
        }

        return {
            collection: firebaseCollection,
            saveAlias: saveAlias
        };

    });


export default ngModule;
