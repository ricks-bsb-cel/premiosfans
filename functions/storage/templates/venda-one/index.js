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

    .factory('httpCalls', function ($http, $q) {
        const auth = getAuth();

        const getUrlEndPoint = url => {
            const localUrl = 'http://localhost:5000';
            const gatewayUrl = 'https://premios-fans-a8fj1dkb.uc.gateway.dev';

            return (window.location.hostname === 'localhost' ? localUrl : gatewayUrl) + url;
        }

        const generateTitulo = data => {
            const token = auth.currentUser ? auth.currentUser.accessToken : null;

            return $q(function (resolve, reject) {

                if (!token) {
                    Swal.fire('Ooops!', 'Não foi possível iniciar a compra...', 'error');
                    return reject();
                }

                if (!data || !data.nome || !data.email || !data.celular || !data.cpf) {
                    Swal.fire('Ooops!', 'Verifique seus dados...', 'error');
                    return reject();
                }

                data = {
                    idCampanha: _idCampanha,
                    idInfluencer: _idInfluencer,
                    nome: data.nome,
                    email: data.email,
                    celular: data.celular,
                    cpf: data.cpf
                };

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/generate-titulo?async=false'),
                    method: 'post',
                    data: data,
                    headers: {
                        'Authorization': 'Bearer ' + token
                    }
                })

                    .then(
                        function (response) {
                            Swal.fire('Título Gerado', `Código do Título: ${response.data.result.data.id}`, 'info');

                            return resolve(response);
                        },
                        function (e) {
                            Swal.fire('Ooops!', e.data.error, 'error');

                            return reject(e);
                        }
                    );
            })
        }

        return {
            generateTitulo: generateTitulo
        }

    })

    .directive('formCliente', function () {
        return {
            restrict: 'E',
            controller: function (
                $scope,
                formClienteFactory,
                httpCalls
            ) {
                $scope.titulo = {};

                const send = _ => {
                    httpCalls.generateTitulo($scope.titulo);
                }

                $scope.initDelegates = _ => {
                    formClienteFactory.delegate = {
                        showFormCliente: _ => {
                            $("#form-cliente").show();
                        },
                        send: _ => {
                            return send();
                        }
                    }
                }
            },
            templateUrl: `/templates/venda-one/form-cliente.html?v=` + _version,
            link: function (scope) {
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

            if (formClienteFactory && formClienteFactory.delegate && typeof formClienteFactory.delegate.showFormCliente === 'function')
                formClienteFactory.delegate.showFormCliente();
        }

        $scope.openSell = _ => {

            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
                return;
            }

            formClienteFactory.delegate.send();
        }


    });
