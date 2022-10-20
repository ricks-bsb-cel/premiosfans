'use strict';

const ngModule = angular.module('collection.empresas', [])

    .factory('collectionEmpresas', function (
        $q,
        globalFactory,
        appAuthHelper,
        appErrors,
        appFirestoreHelper,
        appCollection
    ) {

        const attr = {
            collection: 'empresas',
            autoStartSnapshot: false
        };

        const firebaseCollection = new appCollection(attr);

        const save = function (data) {

            debugger;

            return $q(function (resolve, reject) {

                appAuthHelper.ready()
                    .then(_ => {

                        console.info(data);

                        return reject();

                    })

            })
        }

        return {
            collection: firebaseCollection,
            save: save
        };

    });


export default ngModule;
