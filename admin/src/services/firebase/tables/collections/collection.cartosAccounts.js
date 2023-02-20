'use strict';

const ngModule = angular.module('collection.cartosAccounts', [])

    .factory('collectionCartosAccounts', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper
    ) {

        const attr = {
            collection: 'cartosAccounts',
            autoStartSnapshot: false,
            filterEmpresa: false
        };

        const firebaseCollection = new appCollection(attr);

        async function getByCpf(cpf){
            await appAuthHelper.ready();
            
            let query = appFirestoreHelper.collection(attr.collection);
            query = appFirestoreHelper.query(query, 'cpf', '==', cpf);

            return await appFirestoreHelper.docs(query);
        }

        return {
            collection: firebaseCollection,
            getByCpf: getByCpf
        };

    });


export default ngModule;
