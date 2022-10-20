'use strict';

const ngModule = angular.module('collection.formlySelector', [])

    .factory('collectionsFormlySelector', function (
        $q,
        firebaseService,
        firebaseProvider
    ) {

        var onSnapShotLimit = 0;
        var onSnapShowData = [];

        const get = function (collection) {
            return $q(function (resolve, reject) {

                var result = [];

                firebaseProvider
                    .firestore
                    .collection(collection)
                    .get()
                    .then(function (data) {

                        data.forEach(d => {
                            result.push({
                                value: d.id,
                                label: d.data().label
                            });
                        })

                        result = result.sort(function (a, b) { return a.label > b.label ? 1 : -1; });

                        return resolve(result);

                    }).catch(function (e) {
                        firebaseCollection.showError(e);
                        return reject(e);
                    })

            })
        }

        const create = function (collection, label) {
            return $q(function (resolve, reject) {

                var toAdd = {
                    label: label,
                    inclusao_js: firebaseService.getFirebaseSeconds()
                };

                var newDoc = firebaseProvider.firestore.collection(collection).doc();

                newDoc.set(toAdd).then(function () {
                    toAdd.id = newDoc.id;
                    return resolve(toAdd);
                }).catch(function (e) {
                    firebaseCollection.showError(e);
                    return reject(e);
                })

            })
        }

        const onSnapShot = function (collection, callback) {

            callback(onSnapShowData);
            
            firebaseProvider
                .firestore
                .collection(collection)
                .where('inclusao_js', '>', onSnapShotLimit)
                .onSnapshot(snapshot => {
                    snapshot.docChanges().forEach(function (s) {

                        var data = s.doc.data();
                        var id = s.doc.id;

                        if (s.type == 'removed') {
                            onSnapShowData = onSnapShowData.filter(f => {
                                return f.value != id;
                            })
                        }

                        if (s.type == 'added' || s.type == 'modified') {

                            var i = onSnapShowData.findIndex(f => {
                                return f.value == id;
                            });

                            if (i < 0) {
                                onSnapShowData.push({
                                    value: id,
                                    label: data.label
                                })
                            } else {
                                onSnapShowData.label = data.label;
                            }

                            if (onSnapShotLimit < data.inclusao_js) {
                                onSnapShotLimit = data.inclusao_js;
                            }

                        }

                        callback(onSnapShowData);
                    })

                });
        }

        return {
            get: get,
            create: create,
            onSnapShot: onSnapShot
        };

    });


export default ngModule;
