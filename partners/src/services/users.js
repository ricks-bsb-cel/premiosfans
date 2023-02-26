'use strict';

const ngModule = angular.module('services.userService', [])

    .factory('userService',
        function (
            appAuthHelper,
            globalFactory,
            appDatabase,
            appDatabaseHelper,
            appFunctions,
            waitUiFactory,
            $window,
            $http,
            URLs,
        ) {


            const zoepayAccountCurrentUser = _ => {
                return new Promise((resolve, reject) => {

                    appAuthHelper.ready()

                        .then(currentUser => {
                            const path = `zoeAccount/${currentUser.uid}/pf`;
                            return appDatabaseHelper.once(path);
                        })

                        .then(userData => {
                            return resolve(userData);
                        })

                        .catch(e => {
                            return reject(e);
                        })

                })
            }

            const checkCpfCelular = (cpf, celular, callback) => {

                const functions = appFunctions.getFunctions();

                const id = $window.localStorage.idlogin || globalFactory.guid();
                const hash = globalFactory.guid();

                $window.localStorage.idlogin = id;

                const checkUserAppByCelular = appFunctions.httpsCallable(functions, 'checkUserAppByCelular');
                const dbPath = appDatabase.ref(appDatabase.database, '_ic/' + id);

                waitUiFactory.start();

                checkUserAppByCelular({
                    cpf: cpf,
                    celular: celular,
                    id: id,
                    hash: hash
                })
                    .then(_ => {

                        appDatabase.onValue(dbPath, snapshot => {
                            snapshot = snapshot.val();
                            if (snapshot !== null && snapshot.hash === hash) {
                                appDatabase.off(dbPath);
                                waitUiFactory.stop();
                                callback(snapshot);
                            }
                        });

                    })

                    .catch(e => {
                        console.error(e);
                    })

            }

            const checkCpfAberturaConta = (cpf, callback) => {

                const functions = appFunctions.getFunctions();

                const id = $window.localStorage.idlogin || globalFactory.guid();
                const hash = globalFactory.guid();

                $window.localStorage.idlogin = id;

                const checkCpfInicioAberturaConta = appFunctions.httpsCallable(functions, 'checkCpfInicioAberturaConta');

                const dbPath = appDatabase.ref(appDatabase.database, '_ic/' + id);

                waitUiFactory.start();

                checkCpfInicioAberturaConta({
                    cpf: cpf,
                    id: id,
                    hash: hash
                })
                    .then(_ => {

                        appDatabase.onValue(dbPath, snapshot => {
                            snapshot = snapshot.val();

                            if (snapshot !== null && snapshot.hash === hash) {
                                appDatabase.off(dbPath);

                                waitUiFactory.stop();
                                callback(snapshot);
                            }

                        });

                    })

                    .catch(e => {
                        console.error(e);
                    })

            }

            const init = attrs => {

                waitUiFactory.start();

                $http({
                    url: URLs.user.account.init,
                    method: 'post',
                    headers: { 'Authorization': 'Bearer ' + appAuthHelper.token }
                }).then(
                    function (response) {
                        waitUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success(response.data.data);
                        }
                    },
                    function (e) {
                        waitUiFactory.stop();
                        if (typeof attrs.error === 'function') {
                            console.error(e);
                            attrs.error(e);
                        }
                    }
                );
            }

            const emailResendCode = attrs => {

                waitUiFactory.start();

                $http({
                    url: URLs.user.account.emailResendCode,
                    method: 'get',
                    headers: { 'Authorization': 'Bearer ' + appAuthHelper.token }
                }).then(
                    function (response) {
                        waitUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success(response.data.data);
                        }
                    },
                    function (e) {
                        waitUiFactory.stop();
                        console.error(e);
                        if (typeof attrs.error === 'function') {
                            attrs.error(e);
                        }
                    }
                );
            }

            const emailCode = attrs => {

                if (!attrs.code) {
                    throw new Error('code required');
                }

                waitUiFactory.start();

                $http({
                    url: URLs.user.account.emailCode,
                    method: 'post',
                    headers: { 'Authorization': 'Bearer ' + appAuthHelper.token },
                    data: { code: attrs.code }
                }).then(
                    function (response) {
                        waitUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success(response.data.data);
                        }
                    },
                    function (e) {
                        waitUiFactory.stop();
                        console.error(e);
                        if (typeof attrs.error === 'function') {
                            attrs.error(e);
                        }
                    }
                );
            }

            const accountOpen = attrs => {

                if (!attrs.type || !attrs.CpfCnpj) {
                    throw new Error('code required');
                }

                waitUiFactory.start();

                $http({
                    url: URLs.user.account.accountOpen,
                    method: 'post',
                    headers: { 'Authorization': 'Bearer ' + appAuthHelper.token },
                    data: {
                        type: attrs.type,
                        CpfCnpj: attrs.CpfCnpj
                    }
                }).then(
                    function (response) {
                        waitUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success(angular.merge(response.data.data || response.data, { success: true }));
                        }
                    },
                    function (e) {
                        waitUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success({ success: false, error: e.message || e });
                        }
                    }
                );
            }

            return {
                checkCpfCelular: checkCpfCelular,
                checkCpfAberturaConta: checkCpfAberturaConta,
                init: init,
                emailResendCode: emailResendCode,
                emailCode: emailCode,
                accountOpen: accountOpen,
                zoepayAccountCurrentUser: zoepayAccountCurrentUser
            };
        }
    );

export default ngModule;
