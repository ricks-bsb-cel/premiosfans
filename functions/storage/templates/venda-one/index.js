'use strict';

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-app.js";
import { getAuth, onAuthStateChanged, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-auth.js";
import { getMessaging, getToken } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-messaging.js";
import { getFirestore, collection, query, where, onSnapshot } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-firestore.js";

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

const messagingKey = "BIY0gJcJ_octWgJgtcayla50bdJrhDetP6iekjYBkU93_tolz0Kw1HLa4tScldEWkHcrgxzolAqBpV7GkeceN3g";

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

    .factory('init', function ($q, global, comprasClienteFactory, $timeout) {
        let app = null,
            token = null,
            isReady = false,
            messaging = null;

        const init = _ => {
            app = initializeApp(firebaseConfig);
            messaging = getMessaging(app);
            global.unblockUi();
            stateChanged();
        }

        const initMessaging = _ => {
            const messaging = getMessaging();

            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    getToken(messaging, { vapidKey: messagingKey }).then(currentToken => {
                        if (currentToken) {
                            Swal.fire('Token', currentToken, 'success');
                        } else {
                            Swal.fire('Token', 'No registration token available. Request permission to generate one.', 'success');
                        }
                    }).catch(e => {
                        console.error(e);

                        Swal.fire('Error', e.message, 'error');
                    });
                }
            })

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

        const initUser = user => {
            user = user;
            token = user.accessToken;

            setCookie(token);
            checkTokenChange();

            comprasClienteFactory.delegate.refresh();
        }

        const stateChanged = _ => {
            const auth = getAuth();
            onAuthStateChanged(auth, user => {
                if (user) {
                    initUser(user);
                }

                isReady = true;
            })
        }

        const signIn = _ => {
            const auth = getAuth();

            return $q((resolve, reject) => {
                if (token) {
                    return resolve(token);
                }

                signInAnonymously(auth)
                    .then(user => {
                        initUser(user);

                        return resolve(token);
                    })
                    .catch((e) => {
                        console.info(e.code, e.message);
                        return reject(e);
                    });

            })
        }

        return {
            app: app,
            init: init,
            getCurrentUser: getCurrentUser,
            ready: ready,
            signIn: signIn,
            initMessaging: initMessaging
        }

    })

    .factory('httpCalls', function ($http, $q, global, init) {
        const auth = getAuth();

        const getUrlEndPoint = url => {
            const localUrl = 'http://localhost:5000';
            const gatewayUrl = 'https://premios-fans-a8fj1dkb.uc.gateway.dev';

            return (window.location.hostname === 'localhost' ? localUrl : gatewayUrl) + url;
        }

        const generateCompra = data => {
            let token = null;

            return $q(function (resolve, reject) {

                global.blockUi();

                init.signIn()
                    .then(signInResult => {
                        token = signInResult;

                        if (!data || !data.nome || !data.email || !data.celular || !data.cpf) {
                            Swal.fire('Ooops!', 'Verifique seus dados...', 'error');
                            return reject();
                        }

                        data = {
                            idCampanha: _idCampanha,
                            idInfluencer: _idInfluencer,
                            nome: data.nome,
                            email: data.email,
                            celular: data.celular.replace(/\D/g, ""),
                            cpf: data.cpf.replace(/\D/g, ""),
                            qtdTitulos: data.qtdTitulos
                        };

                        return $http({
                            url: getUrlEndPoint('/api/eeb/v1/generate-compra?async=false'),
                            method: 'post',
                            data: data,
                            headers: {
                                'Authorization': 'Bearer ' + token
                            }
                        })

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
            generateCompra: generateCompra
        }

    })

    .factory('comprasClienteFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })
    .directive('comprasCliente', function () {
        return {
            restrict: 'E',
            controller: function ($scope, init, comprasClienteFactory, pagarCompraFactory, detalhesCompraFactory, $timeout) {
                let refreshTimeout, unsubscribeSnapshot;

                $scope.compras = [];

                const initSnapshot = _ => {
                    const user = init.getCurrentUser();
                    if (!user) return;

                    init.ready().then(app => {
                        let
                            db = getFirestore(app),
                            q = collection(db, "titulosCompras");

                        q = query(q, where("idCampanha", "==", _idCampanha));
                        q = query(q, where("uidComprador", "==", user.uid));

                        if (unsubscribeSnapshot) unsubscribeSnapshot();

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

                comprasClienteFactory.delegate = {
                    refresh: _ => {
                        initSnapshot();
                    }
                }

                initSnapshot();

                $scope.pagar = tituloCompra => {
                    pagarCompraFactory.delegate.show(tituloCompra);
                }

                $scope.detalhes = tituloCompra => {
                    detalhesCompraFactory.delegate.show(tituloCompra);
                }
            },
            templateUrl: 'compras-cliente.htm'
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
            controller: function ($scope, formClienteFactory, pagarCompraFactory, httpCalls) {
                let element = null;

                $scope.compra = {};

                const send = qtdTitulos => {
                    if (!$scope.compra ||
                        !$scope.compra.nome ||
                        !$scope.compra.email ||
                        !$scope.compra.celular ||
                        !$scope.compra.cpf
                    ) {
                        Swal.fire('Dados inválidos', 'Por favor, preencha corretamente todos os campos para realizar a compra.', 'error');

                        return;
                    }

                    $scope.compra.qtdTitulos = qtdTitulos;

                    // Abre a modal de confirmação dos dados, pedido da compra, etc.
                    pagarCompraFactory.delegate.show($scope.compra);

                    // httpCalls.generateCompra($scope.titulo);
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
            templateUrl: 'form-cliente.htm',
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
                $scope.compra = null;
                let element = null;

                $scope.close = _ => {
                    modal.close();
                    $scope.visible = false;
                }

                $scope.sendCompra = _ => {
                    console.info('done');

                    element.find('.adquirir').hide();
                    element.find('.send-compra-wait').show();

                    debugger;


                }

                $scope.initDelegates = e => {
                    element = e;

                    pagarCompraFactory.delegate = {
                        show: compra => {
                            $scope.compra = compra;
                            $scope.visible = true;

                            modal.open("pagar-compra");
                        }
                    }
                }
            },
            templateUrl: 'modal-pagar-compra.htm',
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
            templateUrl: 'modal-detalhe-compra.htm',
            link: function (scope, element) {
                scope.initDelegates(element);
            }
        };
    })



    .factory('modalRegulamentoFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })
    .directive('modalRegulamento', function () {
        return {
            restrict: 'E',
            controller: function ($scope, modalRegulamentoFactory, modal) {
                $scope.visible = false;
                let element = null;

                $scope.close = _ => {
                    modal.close();
                    $scope.visible = false;
                }

                $scope.initDelegates = e => {
                    element = e;

                    modalRegulamentoFactory.delegate = {
                        show: _ => {
                            $scope.visible = true;
                            modal.open("modal-regulamento");
                        }
                    }
                }
            },
            templateUrl: 'modal-regulamento.htm',
            link: function (scope, element) {
                scope.initDelegates(element);
            }
        };
    })


    .directive('faq', function () {
        return {
            restrict: 'E',
            controller: function ($scope,) {
                $scope.list = [
                    { p: "Quais são as Formas de Pagamento?", r: "No momento aceitamos apenas PIX como forma de pagamento." },
                    { p: "Como recuperar minhas compras?", r: "Você pode ver todos os títulos comprados no mesmo dispositivo onde você realizou a compra, ou, procure a opção 'Recuperar Compras' no menu e informe seu email ou número do celular." },
                ]
            },
            templateUrl: 'faq.htm'
        };
    })


    .controller('mainController', function (
        $scope,
        formClienteFactory,
        modalRegulamentoFactory,
        init
    ) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal, qtd) => {
            $scope.selected = id;
            $scope.qtd = qtd;
            $scope.vlCompra = vlTotal;

            $("#vl-total").show();

            // init.initMessaging();

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

        $scope.showRegulamento = _ => {
            modalRegulamentoFactory.delegate.show();
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
