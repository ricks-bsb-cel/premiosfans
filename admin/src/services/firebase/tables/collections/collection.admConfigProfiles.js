'use strict';

const ngModule = angular.module('collection.admConfigProfiles', [])

    .factory('collectionAdmConfigProfiles', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper,
        $q
    ) {

        const firebaseCollection = new appCollection({
            collection: 'admConfigProfiles',
            autoStartSnapshot: true
        });

        const getById = id => {
            return appFirestoreHelper.getDoc('admConfigProfiles', id);
        }

        const save = data => {
            return $q((resolve, reject) => {

                var id = data.id || 'new';

                var update = {
                    titulo: data.titulo,
                    groups: [],
                    collections: {},
                    idUser: appAuthHelper.user.uid,
                    dtAlteracao: appFirestoreHelper.currentTimestamp()
                };

                if (id !== 'new' || !data.dtInclusao) {
                    update.dtInclusao = appFirestoreHelper.currentTimestamp();
                }

                data.groups.forEach(g => {

                    var group = {
                        id: g.id,
                        icon: g.icon,
                        titulo: g.titulo,
                        options: []
                    };

                    g.options.forEach(o => {

                        group.options.push({
                            id: o.id,
                            label: o.label,
                            create: o.create,
                            update: o.update,
                            delete: o.delete
                        });

                        if (o.collection && typeof update.collections[o.collection] === 'undefined') {
                            update.collections[o.collection] = {
                                create: typeof o.create === 'boolean' ? o.create : false,
                                update: typeof o.update === 'boolean' ? o.update : false,
                                delete: typeof o.delete === 'boolean' ? o.delete : false
                            }
                        }

                    });

                    update.groups.push(group);
                })

                firebaseCollection
                    .addOrUpdateDoc(id, update)
                    .then(data => {
                        return resolve(data);
                    })
                    .catch(e => {
                        return reject(e);
                    })
            })
        }

        return {
            collection: firebaseCollection,
            getById: getById,
            save: save
        };

    });

export default ngModule;
