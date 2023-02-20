'use strict';

const ngModule = angular.module('collection.cartosPixKeys', [])

    .factory('collectionCartosPixKeys', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper
    ) {
        const attr = {
            collection: 'cartosPixKeys',
            autoStartSnapshot: true,
            filterEmpresa: false,
            orderBy: 'owner.name'
        };

        const firebaseCollection = new appCollection(attr);

        async function getByAccountId(cpf, accountId) {
            await appAuthHelper.ready();

            let query = appFirestoreHelper.collection(attr.collection);
            query = appFirestoreHelper.query(query, 'cpf', '==', cpf);
            query = appFirestoreHelper.query(query, 'accountId', '==', accountId);

            return await appFirestoreHelper.docs(query);
        }

        async function getByCpf(cpf) {
            await appAuthHelper.ready();

            let query = appFirestoreHelper.collection(attr.collection);
            query = appFirestoreHelper.query(query, 'cpf', '==', cpf);

            return await appFirestoreHelper.docs(query);
        }

        return {
            collection: firebaseCollection,
            getByAccountId: getByAccountId,
            getByCpf: getByCpf
        };
    });


export default ngModule;
