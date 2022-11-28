'use strict';

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-app.js";
import { getAuth, onAuthStateChanged, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-auth.js";
import { getFirestore, collection, query, where, getDocs } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-firestore.js";

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

angular.module('app', [])

    .run(function (init) {
        init.init();
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

        const blockUi = _ => {
            $('#wait').show();
        }

        const unblockUi = _ => {
            $('#wait').hide()
        }

        return {
            guid: guid,
            blockUi: blockUi,
            unblockUi: unblockUi
        }
    })

    .factory('init', function (global) {
        let app = null,
            token = null,
            userData = {};

        const init = _ => {
            app = initializeApp(firebaseConfig);
            global.unblockUi();
            stateChanged();
        }

        const getToken = _ => {
            return token;
        }

        const setCookie = token => {
            document.cookie = `__anonymousSession=${token}; path=/`;
        }

        const checkTokenChange = () => {
            const auth = getAuth();
            auth.onIdTokenChanged(user => {
                token = user.accessToken;
                setCookie(token);
            });
        }

        const getCurrentUser = _ => {
            const auth = getAuth();
            return auth.currentUser;
        }

        const stateChanged = _ => {
            const auth = getAuth();
            onAuthStateChanged(auth, user => {
                if (!user) return signIn();
                token = auth.currentUser.accessToken || null;
                setCookie(token);
                checkTokenChange();
                loadUserData();
            })
        }

        const getUserCompras = _ => {
            return userData.compras || [];
        }

        const loadUserData = _ => {
            const user = getCurrentUser(),
                db = getFirestore(app);
            let q = collection(db, "titulosCompras");

            q = query(q, where("idCampanha", "==", _idCampanha));
            q = query(q, where("uidComprador", "==", user.uid));

            return getDocs(q)
                .then(docs => {
                    userData.compras = [];

                    docs.forEach(d => {
                        userData.compras.push(angular.merge(d.data(), { id: d.id }));
                    })
                })
                .catch(e => {
                    console.error(e);
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
            getToken: getToken,
            loadUserData: loadUserData,
            getUserCompras: getUserCompras
        }

    })

    .factory('httpCalls', function ($http, $q, global, init) {
        const auth = getAuth();

        const getUrlEndPoint = url => {
            const localUrl = 'http://localhost:5000';
            const gatewayUrl = 'https://premios-fans-a8fj1dkb.uc.gateway.dev';

            return (window.location.hostname === 'localhost' ? localUrl : gatewayUrl) + url;
        }

        const loadUserData = _ =>{
            init.loadUserData();
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

                global.blockUi();

                data = {
                    idCampanha: _idCampanha,
                    idInfluencer: _idInfluencer,
                    nome: data.nome,
                    email: data.email,
                    celular: data.celular.replace(/\D/g, ""),
                    cpf: data.cpf.replace(/\D/g, ""),
                    qtdTitulos: data.qtdTitulos
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
                            global.unblockUi();
                            Swal.fire('Título Gerado', `Código da Compra: ${response.data.result.data.compra.id}`, 'info');
                            
                            loadUserData();

                            return resolve(response);
                        },
                        function (e) {
                            global.unblockUi();
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

    .factory('formClienteFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
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
                let element = null;

                $scope.titulo = {};

                const send = qtdTitulos => {
                    $scope.titulo.qtdTitulos = qtdTitulos;
                    httpCalls.generateTitulo($scope.titulo);
                }

                const initMasks = _ => {
                    const eCpf = element.find('input[name="cpf"]'),
                        eCelular = element.find('input[name="celular"]');

                    VMasker(eCpf).maskPattern("999.999.999-99");
                    VMasker(eCelular).maskPattern("(99) 9 9999-9999");
                }

                $scope.initDelegates = e => {
                    element = e;

                    formClienteFactory.delegate = {
                        showFormCliente: _ => {
                            $("#form-cliente").show();
                            initMasks();
                        },
                        send: send
                    }
                }

            },
            templateUrl: `/templates/venda-one/form-cliente.html?v=` + _version,
            link: function (scope, element) {
                scope.initDelegates(element);
            }
        };
    })

    .directive('comprasCliente', function () {
        return {
            restrict: 'E',
            controller: function ($scope, init) {
                $scope.userCompras = _ => {
                    return init.getUserCompras();
                }
            },
            templateUrl: `/templates/venda-one/compras-cliente.html?v=` + _version,
            link: function (scope, element) {
                scope.e = element;
            }
        };
    })

    .controller('mainController', function ($scope, formClienteFactory) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal, qtd) => {
            $scope.selected = id;
            $scope.qtd = qtd;
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

            formClienteFactory.delegate.send($scope.qtd);
        }

    })

    .filter('ddmmhhmm', function () {
        return function (v) {
            if (v) {
                if (typeof v === 'object') {
                    return moment(v.toDate()).format("DD/MM HH:mm");
                } else if (v.substr(10, 1) === 'T' || (v.length === 19 && v.substr(10, 1) === ' ')) {
                    return moment(v).format("DD/MM HH:mm");
                } else {
                    return moment.unix(v).format("DD/MM HH:mm");
                }
            } else {
                return null;
            }
        }
    });
