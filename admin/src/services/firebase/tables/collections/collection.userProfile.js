'use strict';

const ngModule = angular.module('collection.userProfile', [])

    .factory('collectionUserProfile', function (
        appCollection,
        appFirestore,
        appFirestoreHelper,
        appDatabaseHelper,
        globalFactory,
        alertFactory,
        $q
    ) {

        const firebaseCollection = new appCollection({
            collection: 'userProfile'
        });

        const checkApiKey = (apikey, id) => {
            return $q((resolve, reject) => {

                if (!apikey) {
                    return resolve();
                }

                firebaseCollection.query(`apikey == ${apikey}`)
                    .then(queryResult => {
                        if (queryResult.length > 0 && queryResult[0].id !== id) {
                            throw new Error(`A apikey já está sendo utilizada em outro usuário [${queryResult[0].email}]`);
                        }

                        return resolve();
                    })

                    .catch(e => {
                        return reject(e);
                    })

            })
        }

        const save = function (data) {

            var setApiKey;

            return $q(function (resolve, reject) {

                if (!data.id) {
                    throw new Error('o ID é obrigatório...');
                }

                data.apikey = globalFactory.sanitize(data.apikey);

                const id = data.id;

                var toUpdate = {
                    email: data.email || null,
                    displayName: data.displayName || null,
                    photoURL: data.photoURL || null,
                    phoneNumber: data.phoneNumber || null,
                    ativo: typeof data.ativo === 'boolean' ? data.ativo : true,
                    keywords: globalFactory.generateKeywords(
                        data.displayName,
                        data.email,
                        data.phoneNumber
                    ),
                    dtAlteracao: appFirestoreHelper.currentTimestamp(),
                    qtdEmpresas: data.perfilEmpresas.length,
                    apikey: data.apikey || null,
                    apiDirectCall: data.apiDirectCall || false,
                    idsEmpresas: [],
                    idsPerfils: []
                }

                if (toUpdate.phoneNumber && !toUpdate.phoneNumber.startsWith('+')) {
                    toUpdate.phoneNumber = '+' + toUpdate.phoneNumber;
                }

                data.perfilEmpresas.forEach(p => {
                    if (!toUpdate.idsEmpresas.includes(p.data.idEmpresa)) {
                        toUpdate.idsEmpresas.push(p.data.idEmpresa);
                    }
                    if (!toUpdate.idsPerfils.includes(p.data.idPerfil)) {
                        toUpdate.idsPerfils.push(p.data.idPerfil);
                    }
                })

                checkApiKey(data.apikey, id)

                    .then(_ => {
                        return firebaseCollection.addOrUpdateDoc(id, toUpdate);
                    })

                    .then(_ => {
                        return saveEmpresa(id, data.perfilEmpresas);
                    })

                    .then(_ => {

                        if (data.apikey) {

                            const path = `/apikey/${id}`;

                            var toSave = {
                                apikey: data.apikey,
                                idsEmpresas: []
                            };

                            data.perfilEmpresas.forEach(e => { toSave.idsEmpresas.push(e.data.idEmpresa); })

                            setApiKey = appDatabaseHelper.set(path, toSave);

                        } else {
                            setApiKey = _ => { return $q(resolve => { return resolve(null); }) }
                        }

                        return setApiKey;
                    })

                    .then(_ => {
                        return resolve(data);
                    })

                    .catch(e => {
                        alertFactory.error(e);
                        return reject(e);
                    })

            })
        }

        const saveEmpresa = (id, perfilEmpresas) => {
            return $q((resolve, reject) => {

                var promisses = [];
                var idsEmpresasExistentes = [];
                var result = [];

                // Por ser um processo mais complexo vou usar diretamente o firestore (e não o appFirestoreHelper)...
                const firestore = appFirestore.firestore;
                const empresasUserProfile = appFirestore.collection(firestore, 'userProfile', id, 'empresas');
                const queryEmpresasUserProfile = appFirestore.query(empresasUserProfile);

                appFirestore.getDocs(queryEmpresasUserProfile)
                    .then(resultEmpresas => {

                        // Carrega as empresas que já estão adicionadas
                        resultEmpresas.forEach(e => {
                            idsEmpresasExistentes.push(e.id);
                        })

                        // Remove dados inconpletos
                        perfilEmpresas = perfilEmpresas.filter(f => {
                            return f.data && f.data.idEmpresa && f.data.idPerfil;
                        })

                        // Seta as que foram solicitadas
                        perfilEmpresas.forEach(p => {

                            promisses.push(
                                appFirestore.setDoc(
                                    appFirestore.doc(firestore, 'userProfile', id, 'empresas', p.data.idEmpresa),
                                    {
                                        idPerfil: p.data.idPerfil,
                                        idEmpresa_reference: appFirestore.doc(firestore, 'empresas', p.data.idEmpresa),
                                        idPerfil_reference: appFirestore.doc(firestore, 'admConfigProfiles', p.data.idPerfil)
                                    }
                                )
                            );

                            result.push({
                                idEmpresa: p.data.idEmpresa,
                                idPerfil: p.data.idPerfil
                            });

                        })

                        // Remove as que não existem mais
                        idsEmpresasExistentes.forEach(idEmpresa => {
                            if (perfilEmpresas.findIndex(f => { return f.data.idEmpresa === idEmpresa; }) < 0) {
                                promisses.push(
                                    appFirestore.deleteDoc(
                                        appFirestore.doc(firestore, 'userProfile', id, 'empresas', idEmpresa)
                                    )
                                );
                            }
                        })

                        return Promise.all(promisses);
                    })

                    .then(() => {
                        return resolve(result);
                    })

                    .catch(e => {
                        return reject(e);
                    })

            })
        }

        /*
        const setEmpresaDefault = (uid, idEmpresas) => {
            return $q(function (resolve, reject) {
         
                if (idEmpresas.length == 0) {
                    return resolve(true);
                }
         
                firebaseCollection.ref.doc(uid).get()
         
                    .then(profile => {
         
                        if (profile.exists && idEmpresas.includes(profile.data().idEmpresaAtual)) {
                            return resolve(true);
                        }
         
                        return save({ idEmpresaAtual: idEmpresas[0] }, uid);
                    })
         
                    .then(data => {
                        return resolve(data);
                    })
         
                    .catch(e => {
                        return reject(e);
                    })
         
            })
        }
        */

        const getEmpresas = (id, loadSubcollections) => {
            return $q((resolve, reject) => {

                var promissesEmpresas = [];
                var promissesPerfis = [];
                var profiles = [];

                appFirestoreHelper.getSubCollection('userProfile', id, 'empresas')

                    .then(resultEmpresasUserProfile => {

                        resultEmpresasUserProfile.forEach(profile => {

                            if (loadSubcollections) {
                                if (profiles.findIndex(f => { return f.idEmpresa === profile.idEmpresa; }) < 0) {
                                    promissesEmpresas.push(appFirestoreHelper.getDoc(profile.idEmpresa_reference));
                                }
                                if (profiles.findIndex(f => { return f.idPerfil === profile.idPerfil; }) < 0) {
                                    promissesPerfis.push(appFirestoreHelper.getDoc(profile.idPerfil_reference));
                                }
                            }

                            profiles.push({
                                idEmpresa: profile.id,
                                idPerfil: profile.idPerfil
                            });

                        });

                        return Promise.all(promissesEmpresas);

                    })

                    .then(resultPromissesEmpresas => {

                        resultPromissesEmpresas.forEach(r => {
                            profiles.map(p => {
                                if (p.idEmpresa === r.id) {
                                    p.empresa = r;
                                }
                            })
                        })

                        return Promise.all(promissesPerfis);
                    })

                    .then(resultPromissesPerfis => {

                        resultPromissesPerfis.forEach(r => {
                            profiles.map(p => {
                                if (p.idPerfil === r.id) {
                                    p.perfil = r;
                                }
                            })
                        })

                        return resolve(profiles);
                    })

                    .catch(e => {
                        console.error(e);
                        return reject(e);
                    })

            })
        }

        return {
            collection: firebaseCollection,
            getEmpresas: getEmpresas,
            save: save
            /*
            setEmpresaDefault: setEmpresaDefault,
            */
        };

    });


export default ngModule;
