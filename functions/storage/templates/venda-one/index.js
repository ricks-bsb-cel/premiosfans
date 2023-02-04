'use strict';

import { initializeApp } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-app.js";
import { getAuth, onAuthStateChanged, signInAnonymously } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-auth.js";
import { getMessaging, getToken } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-messaging.js";
import { getDatabase, ref, onValue } from "https://www.gstatic.com/firebasejs/9.14.0/firebase-database.js";

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

        const scrollToId = id => {
            const e = $(`#${id}`);
            return $("html, body").animate({
                scrollTop: e.offset().top
            }, 500);
        }

        return {
            guid: guid,
            blockUi: blockUi,
            unblockUi: unblockUi,
            scrollToId: scrollToId
        }
    })

    .factory('init', function ($q, global, $timeout) {
        let app = null,
            token = null,
            isReady = false,
            messaging = null,
            TitulosComprasUsuario = [],
            observerTitulosComprasUsuario = {};

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

            initQueryTitulosComprasCliente();
        }

        const stateChanged = _ => {
            const auth = getAuth();
            onAuthStateChanged(auth, user => {
                if (user) {
                    console.info('user uid', user.uid);

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
                    .then(signInAnonymouslyResult => {
                        initUser(signInAnonymouslyResult.user);

                        return resolve(token);
                    })
                    .catch((e) => {
                        console.error(e);

                        return reject(e);
                    });

            })
        }

        const watchTituloCompraUsuario = (idTituloCompra, callback) => {
            unwatchTituloCompraUsuario();

            observerTitulosComprasUsuario[idTituloCompra] = { f: callback };

            const pos = TitulosComprasUsuario.findIndex(f => { return f.id === idTituloCompra; });

            if (pos >= 0 && TitulosComprasUsuario[pos].pixData) callback(TitulosComprasUsuario[pos]);
        }

        const unwatchTituloCompraUsuario = _ => {
            observerTitulosComprasUsuario = {};
        }

        const initQueryTitulosComprasCliente = _ => {
            const
                db = getDatabase(),
                user = getCurrentUser(),
                uid = user.uid,
                refPath = ref(db, `titulosCompras/${_idCampanha}/${uid}`);

            onValue(refPath, snapshot => {
                snapshot = snapshot.val();

                if (!snapshot) return;

                Object.keys(snapshot).forEach(idTituloCompra => {
                    const tituloCompra = Object.assign(snapshot[idTituloCompra], { id: idTituloCompra });

                    $timeout(_ => {
                        const pos = TitulosComprasUsuario.findIndex(f => { return f.id === idTituloCompra; });
                        if (pos < 0) {
                            TitulosComprasUsuario.push(tituloCompra);
                        } else {
                            TitulosComprasUsuario[pos] = tituloCompra;
                        }
                    });

                    if (
                        typeof observerTitulosComprasUsuario[idTituloCompra] !== 'undefined' &&
                        typeof observerTitulosComprasUsuario[idTituloCompra].f === 'function'
                    ) {
                        observerTitulosComprasUsuario[idTituloCompra].f(tituloCompra);
                    }

                })

            });
        }

        const getLastCompra = _ => {
            if (!TitulosComprasUsuario || TitulosComprasUsuario.length === 0) return;
            return TitulosComprasUsuario
                .slice()
                .sort(function (a, b) {
                    return b.dtInclusao.localeCompare(a.dtInclusao);
                })[0];
        }

        return {
            app: app,
            init: init,
            getCurrentUser: getCurrentUser,
            ready: ready,
            signIn: signIn,
            initMessaging: initMessaging,
            TitulosComprasUsuario: TitulosComprasUsuario,
            watchTituloCompraUsuario: watchTituloCompraUsuario,
            unwatchTituloCompraUsuario: unwatchTituloCompraUsuario,
            getLastCompra: getLastCompra
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
                            headers: { 'Authorization': 'Bearer ' + token }
                        })

                    })

                    .then(
                        function (response) {
                            global.unblockUi();

                            return resolve(response);
                        },
                        function (e) {
                            console.error(e);
                            global.unblockUi();

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

        return { delegate: delegate };
    })
    .directive('comprasCliente', function () {
        return {
            restrict: 'E',
            controller: function ($scope, global, init, comprasClienteFactory, pagarCompraFactory, $timeout) {
                $scope.compras = init.TitulosComprasUsuario;

                const scrollToCompra = idCompra => {
                    $timeout(_ => {
                        global.scrollToId(`titulo-compra-${idCompra}`);
                    }, 1000)
                }

                comprasClienteFactory.delegate = {
                    scrollToCompra: scrollToCompra
                }

                $scope.pagar = tituloCompra => {
                    pagarCompraFactory.delegate.show(tituloCompra);
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
            controller: function ($scope, init, mainControllerFactory, global, formClienteFactory, httpCalls, comprasClienteFactory, pagarCompraFactory) {
                let element = null,
                    idTituloCompra;

                $scope.compra = $scope.compra || {};

                const tituloCompraChanged = tituloCompra => {
                    if (tituloCompra.pixData) {
                        init.unwatchTituloCompraUsuario();
                        Swal.close();
                        pagarCompraFactory.delegate.show(tituloCompra);
                    }
                }

                const sendPedidoCompra = qtdTitulos => {

                    if (!$scope.compra || !$scope.compra.nome || !$scope.compra.email || !$scope.compra.celular || !$scope.compra.cpf) {
                        return Swal.fire('Dados inválidos', 'Por favor, preencha corretamente todos os campos para realizar a compra.', 'error');
                    }

                    if (!$scope.compra.idade) {
                        return Swal.fire('Sua Idade', 'Por favor, confirme que você tem 16 anos ou mais.', 'error');
                    }

                    if (!$scope.compra.termos) {
                        return Swal.fire('Termos e Condições', 'Por favor, concorde com os Termos e Condições de Uso.', 'error');
                    }

                    $scope.compra = {
                        nome: $scope.compra.nome,
                        email: $scope.compra.email,
                        celular: $scope.compra.celular,
                        cpf: $scope.compra.cpf,
                        qtdTitulos: qtdTitulos || 1,
                        idade: $scope.compra.idade,
                        termos: $scope.compra.termos
                    };

                    Swal.fire({
                        title: 'Confirme seus dados',
                        icon: 'info',
                        html: `
                            <small style="display:block;margin-bottom:20px;">Verifique se os seus dados estão corretos antes de prosseguir com a compra</small>
                            <h4 class="m-5" style="color:black;">${$scope.compra.nome}</h4>
                            <p class="m-5" style="color:black;">${$scope.compra.email}</p>
                            <p class="m-5" style="color:black;"><small>Celular: </small>${$scope.compra.celular}</p>
                            <p class="m-5" style="color:black;"><small>CPF: </small>${$scope.compra.cpf}</p>
                        `,
                        timer: 0,
                        showCancelButton: true,
                        focusConfirm: true,
                        confirmButtonText: $scope.compra.qtdTitulos === 1 ?
                            `Comprar 1 título` :
                            `Comprar ${$scope.compra.qtdTitulos} títulos`,
                        cancelButtonText: 'Corrigir',
                        allowOutsideClick: false,
                        preConfirm: _ => {

                            Swal.update({
                                title: 'Criando sua compra',
                                html: `<img src="/assets/imgs/wait.svg" /><p>Um momento...</p>`,
                                icon: 'info',
                                showCancelButton: false,
                                showConfirmButton: false
                            });

                            httpCalls.generateCompra($scope.compra)
                                .then(response => {
                                    if (response.data.code !== 200) throw new Error('Erro solicitando compra');

                                    const compra = response.data.result.data.compra;
                                    idTituloCompra = compra.id;

                                    comprasClienteFactory.delegate.scrollToCompra(idTituloCompra);
                                    resetForm();

                                    if (compra.pixData) {
                                        return formClienteFactory.delegate.showPixPagamento(compra);
                                    }

                                    init.watchTituloCompraUsuario(idTituloCompra, tituloCompraChanged);

                                    Swal.update({
                                        title: 'Preparando PIX',
                                        html: `<img src="/assets/imgs/wait.svg" /><p>Um momento...<br />Estamos gerando um PIX para o pagamento da sua compra.</p>`,
                                        icon: 'info',
                                        showCancelButton: false,
                                        showConfirmButton: false
                                    });

                                })
                                .catch(e => {
                                    console.error(e);
                                })

                            return false;
                        }
                    })

                }

                const resetForm = _ => {
                    mainControllerFactory.delegate.resetSelected();
                    $("#form-cliente").hide();
                }

                const initMasks = _ => {
                    const
                        eCpf = element.find('input[name="cpf"]'),
                        eCelular = element.find('input[name="celular"]');

                    VMasker(eCpf).maskPattern("999.999.999-99");
                    VMasker(eCelular).maskPattern("(99) 9 9999-9999");
                }

                const setDadosCompra = compra => {
                    $scope.compra = $scope.compra || {};

                    $scope.compra.nome = compra.compradorNome;
                    $scope.compra.email = compra.compradorEmail;
                    $scope.compra.celular = compra.compradorCelular;
                    $scope.compra.cpf = compra.compradorCpf;
                }

                $scope.initDelegates = e => {
                    element = e;
                    formClienteFactory.delegate = {
                        sendPedidoCompra: sendPedidoCompra,
                        showFormCliente: compra => {
                            if (compra) setDadosCompra(compra);

                            $("#form-cliente").show();
                            initMasks();
                            global.scrollToId('form-cliente');
                        },
                        showPixPagamento: tituloCompraChanged
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
            controller: function ($scope, init, pagarCompraFactory, modal) {
                $scope.visible = false;
                $scope.compra = null;

                let element = null;

                $scope.close = _ => {
                    init.unwatchTituloCompraUsuario();

                    modal.close();

                    $scope.compra = null;
                    $scope.visible = false;
                }

                $scope.CopyPixToClipboard = _ => {
                    if ('clipboard' in navigator) {
                        navigator.clipboard.writeText($scope.compra.pixData.EMV)
                            .then(_ => {
                                Swal.fire({
                                    icon: 'success',
                                    html: `<h3 class="mb-10">Copiado!</h3>`,
                                    width: '240px',
                                    timer: 1200,
                                    showConfirmButton: false
                                });
                            })
                            .catch(e => {
                                Swal.fire({
                                    title: 'Oops',
                                    icon: 'error',
                                    html: e.message,
                                    timer: 5000,
                                    showConfirmButton: false
                                });
                            })
                    } else {
                        Swal.fire({
                            title: 'Oops',
                            html: 'Seu browser não permite o uso do recurso de copiar e colar. Você terá que selecionar, copiar e colar o código manualmente.',
                            timer: 3000,
                            showConfirmButton: false
                        });
                    };
                }

                const tituloCompraChanged = tituloCompra => {
                    $scope.compra = tituloCompra;

                    $('#pagar-compra progress').attr("max", $scope.compra.qtdTotalProcessos);
                    $('#pagar-compra progress').attr("value", $scope.compra.qtdTotalProcessosConcluidos);
                    $('#pagar-compra p.msg').html($scope.compra.msg);
                }

                $scope.initDelegates = e => {
                    element = e;

                    pagarCompraFactory.delegate = {
                        show: tituloCompra => {
                            // Exibição de dados de uma compra, com ou sem pagamento
                            tituloCompraChanged(tituloCompra);

                            $scope.visible = true;

                            init.watchTituloCompraUsuario(tituloCompra.id, tituloCompraChanged);

                            // Exibe o PIX, copia e cola, etc...
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

    .factory('mainControllerFactory', function () {
        let delegate = {};

        return {
            delegate: delegate
        }
    })

    .controller('mainController', function (
        $scope,
        formClienteFactory,
        modalRegulamentoFactory,
        mainControllerFactory,
        init
    ) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal, qtd) => {
            $scope.selected = id;
            $scope.qtd = qtd;
            $scope.vlCompra = vlTotal;

            const lastCompra = init.getLastCompra();

            $("#vl-total").show();

            if (formClienteFactory && formClienteFactory.delegate && typeof formClienteFactory.delegate.showFormCliente === 'function') {
                formClienteFactory.delegate.showFormCliente(lastCompra);
            }
        }

        $scope.openSell = _ => {
            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
                return;
            }

            formClienteFactory.delegate.sendPedidoCompra($scope.qtd);
        }

        $scope.showRegulamento = _ => {
            modalRegulamentoFactory.delegate.show();
        }

        mainControllerFactory.delegate = {
            resetSelected: _ => {
                $scope.selected = null;
            }
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

            /*
            // Close with a click outside
            document.addEventListener('click', event => {
                if (visibleModal != null) {
                    const modalContent = visibleModal.querySelector('article');
                    const isClickInside = modalContent.contains(event.target);
                    !isClickInside && closeModal(visibleModal);
                }
            });
            */

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
