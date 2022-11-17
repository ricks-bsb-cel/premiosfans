'use strict';

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-app.js";
import { getAuth, onAuthStateChanged, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-auth.js";

const firebaseConfig = {
    apiKey: "AIzaSyCAWlJXzEptl2TJ8J4CWeBUaA15o-hSqSs",
    authDomain: "premios-fans.firebaseapp.com",
    databaseURL: "https://premios-fans-default-rtdb.firebaseio.com",
    projectId: "premios-fans",
    storageBucket: "premios-fans.appspot.com",
    messagingSenderId: "801994869227",
    appId: "1:801994869227:web:188d640a390d22aa4831ae",
    measurementId: "G-XTRQ740MSL"
};

angular.module('app', [
])

    .run(function (init) {
        init.init();
    })

    .factory('init', function () {
        let app = null;

        const init = _ => {
            app = initializeApp(firebaseConfig);

            stateChanged();
        }

        const getToken = _ => {
            const auth = getAuth();
            return auth.currentUser ? auth.currentUser.accessToken : null;
        }

        const stateChanged = _ => {
            const auth = getAuth();
            onAuthStateChanged(auth, user => {
                if (!user) {
                    return signIn();
                }

                console.info(getToken());
            })
        }

        const signIn = _ => {
            const auth = getAuth();

            console.info('New user...');

            signInAnonymously(auth)
                .catch((e) => {
                    console.info(e.code, e.message);
                });
        }

        return {
            init: init,
            getToken: getToken
        }

    })

    .factory('global', function () {
        const guid = _ => {
            var d = new Date().getTime();
            var d2 = (performance && performance.now && (performance.now() * 1000)) || 0;
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16;
                if (d > 0) {
                    r = (d + r) % 16 | 0;
                    d = Math.floor(d / 16);
                } else {
                    r = (d2 + r) % 16 | 0;
                    d2 = Math.floor(d2 / 16);
                }
                return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
            });
        };

        return {
            guid: guid
        }
    })

    .factory('formClienteFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })


    .directive('formCliente', function (formClienteFactory) {
        return {
            restrict: 'E',
            controller: function ($scope) {
                $scope.initDelegates = _ => {
                    formClienteFactory.delegate = {
                        showFormCliente: _ => {
                            $("#form-cliente").show();
                        }
                    }
                }
            },
            templateUrl: `/templates/teste-one/form-cliente.html?v=${version}`,
            link: function (scope, element) {
                scope.initDelegates();
            }
        };

    })

    .controller('mainController', function ($scope, formClienteFactory) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal, qtd) => {
            $scope.selected = id;
            $scope.vlCompra = vlTotal;

            $("#vl-total").show();

            formClienteFactory.delegate.showFormCliente();
        }

        $scope.openSell = _ => {
            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
                return;
            }
        }


    });
