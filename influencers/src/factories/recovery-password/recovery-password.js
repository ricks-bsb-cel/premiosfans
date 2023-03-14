'use strict';

let ngModule = angular.module('factories.recovery-password', [])

    .controller('recoveryPasswordController',
        function (
            $uibModalInstance,
            waitUiFactory,
            firebaseProvider,
            firebaseAuthMessages,
            alertFactory,
            $window
        ) {

            var $ctrl = this;

            $ctrl.fields = [
                {
                    key: 'email',
                    type: 'input',
                    className: 'capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        maxlength: 128,
                        minlength: 3,
                        required: true,
                        type: 'email',
                        icon: 'fas fa-envelope'
                    },

                }
            ];

            $ctrl.sendRecoveryPassword = function () {

                var email = $ctrl.model.email;

                if (!email || !email.includes("@")) {
                    alertFactory.error('Por favor, informe um endereço de email válido.');
                    return;
                }

                alertFactory.yesno('Tem certeza que deseja enviar um email de recuperação de senha para ' + email + '?', 'Recuperação de Senha').then(function () {
                    waitUiFactory.start();
                    var url = $window.location.origin + $window.location.pathname + $window.location.hash;
                    firebaseProvider.auth.sendPasswordResetEmail(email, { url: url }).then(function () {
                        waitUiFactory.stop();
                        alertFactory.success('Um email foi enviado para ' + email + '. Verifique sua caixa de mensagens (inclusive spam) e clique no link recebido para alterar sua senha.').then(function () {
                            $uibModalInstance.close();
                        })
                    }).catch(function (error) {
                        waitUiFactory.stop();
                        alertFactory.error(firebaseAuthMessages[error.code]);
                    });
                }).catch(function () { })

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('recoveryPasswordFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function () {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'recovery-password-modal',
                        templateUrl: 'recovery-password/recovery-password.html',
                        controller: 'recoveryPasswordController',
                        controllerAs: '$ctrl',
                        backdrop: false
                    });

                    modal.result.then(function (value) {
                        resolve(value);
                    }, function () {
                        console.info('rejected!');
                        reject();
                    });

                })
            }

            var show = function (e) {
                return $q(function (resolve, reject) {
                    showModal().then(function (e) {
                        resolve(e);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            var factory = {
                show: show
            };

            return factory;
        }
    );

export default ngModule;
