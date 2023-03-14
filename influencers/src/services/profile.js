'use strict';

const ngModule = angular.module('services.profile', [])

    .factory('profileService',
        function (
            appAuthHelper,
            appDatabase,
            $q
        ) {

            const dbPath = (p, id) => {

                if (!appAuthHelper.currentUser || !appAuthHelper.currentUser.uid) {
                    throw new Error('Current user not found...');
                }

                let path = `app/${appAuthHelper.currentUser.uid}/${p}`;

                if (id) {
                    path += '/' + id;
                }

                return appDatabase.ref(appDatabase.database, path)
            }

            const getNextOptionAbertura = (id) => {
                return $q(resolve => {
                    return resolve(
                        appAuthHelper.appUserData['option-abertura'] ?
                            appAuthHelper.appUserData['option-abertura'][id] || null :
                            null
                    );
                })
            }

            const saveNextOptionAbertura = (id, option) => {
                return $q((resolve, reject) => {
                    appDatabase.set(dbPath(`option-abertura/${id}`), { option: option })
                        .then(_ => {
                            return resolve();
                        })
                        .catch(e => {
                            return reject(e);
                        });
                })
            }


            const getUser = _ => {
                return $q(resolve => {
                    return resolve(
                        appAuthHelper.appUserData && appAuthHelper.appUserData.user ?
                            appAuthHelper.appUserData.user :
                            null
                    );
                })
            }

            const saveUser = model => {
                delete model.$$hashKey;
                return $q((resolve, reject) => {
                    appDatabase.update(dbPath('user'), model)
                        .then(_ => {
                            return checkProfile(model);
                        })
                        .then(_ => {
                            return resolve();
                        })
                        .catch(e => { return reject(e); });
                })
            }

            // Salva email, nome e data de nascimento no profile
            // Caso o usuário tenha ido para a abertura de conta
            // de pessoa física ANTES de atualizar o profile
            const checkProfile = model => {
                return $q((resolve, reject) => {

                    appDatabase.get(dbPath('profile'))

                        .then(data => {
                            data = data.val();
                            let update = false;

                            if (!data.displayName) {
                                data.displayName = model.displayName;
                                update = true;
                            }

                            if (!data.email) {
                                data.email = model.email;
                                update = true;
                            }

                            if (!data.dtNascimento) {
                                data.dtNascimento = model.dtNascimento_yyyymmdd;
                                update = true;
                            }

                            if (!update) {
                                return;
                            }

                            appAuthHelper.updateUser({
                                data: data,
                                success: _ => {
                                    return null;
                                },
                                error: e => {
                                    throw new Error(e);
                                }
                            })
                        })
                        .then(_ => {
                            return resolve();
                        })

                        .catch(e => {
                            console.error(e);
                            return reject(e);
                        })
                })
            }


            const getAccount = id => {
                if (!id) { throw new Error('missing id'); }
                return $q(resolve => {
                    return resolve(
                        appAuthHelper.currentUser && appAuthHelper.appUserData && appAuthHelper.appUserData.accounts ?
                            appAuthHelper.appUserData.accounts[id] || null :
                            null
                    );
                })
            }


            const saveAccount = (model, id) => {
                if (!id) {
                    throw new Error('Id é de preenchimento obrigatório...');
                }
                delete model.$$hashKey;
                return $q((resolve, reject) => {
                    appDatabase.update(dbPath('accounts', id), model)
                        .then(_ => { return resolve(); })
                        .catch(e => { return reject(e); });
                })
            }


            const getAccounts = _ => {
                return $q(resolve => {
                    return resolve(
                        appAuthHelper.currentUser && appAuthHelper.appUserData && appAuthHelper.appUserData.accounts ?
                            appAuthHelper.appUserData.accounts :
                            []
                    );
                })
            }

            const getDocumentImages = _ => {
                return $q(resolve => {
                    return resolve(
                        appAuthHelper.appUserData && appAuthHelper.appUserData.docs ?
                            appAuthHelper.appUserData.docs :
                            null
                    );
                })
            }

            const saveDocumentImages = model => {
                delete model.$$hashKey;
                return $q((resolve, reject) => {
                    appDatabase.set(dbPath('docs'), model)
                        .then(_ => { return resolve(); })
                        .catch(e => { return reject(e); });
                })
            }

            return {
                getNextOptionAbertura: getNextOptionAbertura,
                saveNextOptionAbertura: saveNextOptionAbertura,

                getUser: getUser,
                saveUser: saveUser,

                getAccount: getAccount,
                saveAccount: saveAccount,
                getAccounts: getAccounts,

                getDocumentImages: getDocumentImages,
                saveDocumentImages: saveDocumentImages
            };

        }
    );

export default ngModule;
