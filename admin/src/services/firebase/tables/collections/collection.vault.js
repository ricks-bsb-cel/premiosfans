'use strict';

const ngModule = angular.module('collection.vault', [])

    .factory('collectionVault', function (
        firebaseBaseCollection,
        firebaseProvider,
        $q
    ) {

        const firebaseCollection = new firebaseBaseCollection('_vault');

        const save = function (data) {
            return $q(function (resolve, reject) {

                var op = null;

                var id = data.id || 'new';
                var update = angular.copy(data);

                delete update.id;

                update.idUser = firebaseProvider.auth.currentUser.uid;
                update.dtAlteracao = firebaseProvider.firebase.firestore.Timestamp.now();

                if (id == 'new') {
                    update.dtInclusao = firebaseProvider.firebase.firestore.Timestamp.now();

                    op = firebaseCollection.createDoc(update);
                } else {
                    op = firebaseCollection.ref.doc(id).update(update);
                }

                op.then(function () {
                    firebaseCollection.updateDoc(data);
                    resolve(data);
                }).catch(function (e) {
                    firebaseCollection.showError(e);
                    reject(e);
                })

            })
        }

        return {
            collection: firebaseCollection,
            save: save
        };

    });


export default ngModule;
