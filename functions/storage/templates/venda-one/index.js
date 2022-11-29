'use strict';

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-app.js";
import { getAuth, onAuthStateChanged, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-auth.js";
import { getFirestore, collection, query, where, getDocs, onSnapshot } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-firestore.js";

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

    .factory('init', function ($q, global, $timeout) {
        let app = null,
            token = null,
            isReady = false,
            userData = {};

        const init = _ => {
            app = initializeApp(firebaseConfig);
            global.unblockUi();
            stateChanged();
        }

        const ready = _ => {
            return $q((resolve) => {
                const checkIsReady = _ => {
                    if (isReady) return resolve(app);
                    $timeout(_ => { checkIsReady(); }, 200);
                }

                if (checkIsReady()) {
                    return resolve(app);
                }
            })
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
                isReady = true;
            })
        }

        const signIn = _ => {
            const auth = getAuth();

            signInAnonymously(auth)
                .catch((e) => {
                    console.info(e.code, e.message);
                });
        }

        return {
            app: app,
            init: init,
            getToken: getToken,
            getCurrentUser: getCurrentUser,
            ready: ready
        }

    })

    .factory('httpCalls', function ($http, $q, global, init) {
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

    .directive('comprasCliente', function () {
        return {
            restrict: 'E',
            controller: function ($scope, init, pagarCompraFactory, detalhesCompraFactory, $timeout) {
                let unsubscribeSnapshot = null, refreshTimeout;
                $scope.compras = [];

                const initSnapshot = _ => {
                    init.ready().then(app => {
                        const db = getFirestore(app), user = init.getCurrentUser();

                        let q = collection(db, "titulosCompras");

                        q = query(q, where("idCampanha", "==", _idCampanha));
                        q = query(q, where("uidComprador", "==", user.uid));

                        unsubscribeSnapshot = onSnapshot(q, querySnapshot => {

                            querySnapshot.docChanges().forEach(change => {
                                const doc = angular.merge(change.doc.data(), { id: change.doc.id });
                                if (change.type === 'removed') {
                                    $scope.compras = $scope.compras.filter(f => { return f.id !== doc.id; });
                                } else {
                                    const pos = $scope.compras.findIndex(f => { return f.id === doc.id; });
                                    if (pos < 0) {
                                        $scope.compras.push(doc);
                                    } else {
                                        $scope.compras[pos] = doc;
                                    }
                                }
                            })

                            if (refreshTimeout) $timeout.cancel(refreshTimeout);

                            refreshTimeout = $timeout(_ => {
                                $scope.compras = angular.copy($scope.compras);
                            }, 250);
                        })

                    })
                }

                initSnapshot();

                $scope.pagar = tituloCompra => {
                    pagarCompraFactory.delegate.show(tituloCompra);
                }

                $scope.detalhes = tituloCompra => {
                    detalhesCompraFactory.delegate.show(tituloCompra);
                }
            },
            templateUrl: `/templates/venda-one/compras-cliente.html?v=` + _version
        };
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
            controller: function ($scope, formClienteFactory, httpCalls) {
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



    .factory('pagarCompraFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })
    .directive('pagarCompra', function () {
        return {
            restrict: 'E',
            controller: function ($scope, pagarCompraFactory, modal) {
                $scope.visible = false;
                let element = null;

                $scope.close = _ => {
                    modal.close();
                    $scope.visible = false;
                }

                $scope.initDelegates = e => {
                    element = e;

                    pagarCompraFactory.delegate = {
                        show: tituloCompra => {
                            $scope.visible = true;
                            modal.open("pagar-compra");
                        }
                    }
                }
            },
            templateUrl: `/templates/venda-one/pagar-compra.html?v=` + _version,
            link: function (scope, element) {
                scope.initDelegates(element);
            }
        };
    })


    .directive('openDetail', function () {
        return {
            restrict: 'A',
            link: function (scope, element, attr) {
                if (attr.openDetail === 'true') {
                    element.attr('open', 'true');
                } else {
                    element.removeAttr('open');
                }
            }
        }
    })


    .factory('detalhesCompraFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })
    .directive('detalhesCompra', function () {
        return {
            restrict: 'E',
            controller: function ($scope, detalhesCompraFactory, modal) {
                $scope.visible = false;
                let element = null;

                $scope.close = _ => {
                    modal.close();
                    $scope.visible = false;
                }

                $scope.initDelegates = e => {
                    element = e;

                    detalhesCompraFactory.delegate = {
                        show: tituloCompra => {
                            $scope.visible = true;
                            modal.open("detalhes-compra");
                        }
                    }
                }
            },
            templateUrl: `/templates/venda-one/detalhes-compra.html?v=` + _version,
            link: function (scope, element) {
                scope.initDelegates(element);
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

    .factory('modal', function () {
        // Config
        const isOpenClass = 'modal-is-open';
        const openingClass = 'modal-is-opening';
        const closingClass = 'modal-is-closing';
        const animationDuration = 400; // ms

        let visibleModal = null,
            initiated = false,
            currentModal = null;

        const toggleModalByEvent = event => {
            event.preventDefault();
            currentModal = document.getElementById(event.currentTarget.getAttribute('data-target'));
            (typeof (currentModal) !== 'undefined' && currentModal != null)
                && isModalOpen(currentModal) ? closeModal(currentModal) : openModal(currentModal);
        }

        const toggleModalById = id => {
            currentModal = document.getElementById(id);
            (typeof (currentModal) !== 'undefined' && currentModal != null) && isModalOpen(currentModal) ? closeModal(currentModal) : openModal(currentModal);
        }

        const isModalOpen = modal => {
            return modal.hasAttribute('open') && modal.getAttribute('open') != 'false' ? true : false;
        }

        const openModal = modal => {
            if (isScrollbarVisible()) {
                document.documentElement.style.setProperty('--scrollbar-width', `${getScrollbarWidth()}px`);
            }
            document.documentElement.classList.add(isOpenClass, openingClass);
            setTimeout(() => {
                visibleModal = modal;
                document.documentElement.classList.remove(openingClass);
            }, animationDuration);
            modal.setAttribute('open', true);
        }

        const closeModal = modal => {
            modal = modal || currentModal;
            visibleModal = null;
            document.documentElement.classList.add(closingClass);
            setTimeout(() => {
                document.documentElement.classList.remove(closingClass, isOpenClass);
                document.documentElement.style.removeProperty('--scrollbar-width');
                modal.removeAttribute('open');
            }, animationDuration);
        }

        const init = _ => {
            if (initiated) return;
            initiated = true;

            // Close with a click outside
            document.addEventListener('click', event => {
                if (visibleModal != null) {
                    const modalContent = visibleModal.querySelector('article');
                    const isClickInside = modalContent.contains(event.target);
                    !isClickInside && closeModal(visibleModal);
                }
            });

            // Close with Esc key
            document.addEventListener('keydown', event => {
                if (event.key === 'Escape' && visibleModal != null) {
                    closeModal(visibleModal);
                }
            });

        }

        const getScrollbarWidth = () => {

            // Creating invisible container
            const outer = document.createElement('div');
            outer.style.visibility = 'hidden';
            outer.style.overflow = 'scroll'; // forcing scrollbar to appear
            outer.style.msOverflowStyle = 'scrollbar'; // needed for WinJS apps
            document.body.appendChild(outer);

            // Creating inner element and placing it in the container
            const inner = document.createElement('div');
            outer.appendChild(inner);

            // Calculating difference between container's full width and the child width
            const scrollbarWidth = (outer.offsetWidth - inner.offsetWidth);

            // Removing temporary elements from the DOM
            outer.parentNode.removeChild(outer);

            return scrollbarWidth;
        }

        const isScrollbarVisible = () => {
            return document.body.scrollHeight > screen.height;
        }

        init();

        return {
            show: toggleModalByEvent,
            open: toggleModalById,
            close: closeModal
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
