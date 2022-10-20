'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

(function () {

    ngModule = angular.module('factories.new-password', [])

        .controller('newPasswordController',
            function (
                $uibModalInstance,
                blockUiFactory,
                firebaseProvider,
                firebaseAuthMessages,
                alertFactory,
                parms
            ) {

                var $ctrl = this;

                $ctrl.parms = parms;

                $ctrl.fields = [
                    {
                        key: 'senha1',
                        type: 'input',
                        templateOptions: {
                            label: 'Senha',
                            maxlength: 32,
                            minlength: 3,
                            required: true,
                            type: 'password',
                            icon: 'fas fa-lock'
                        }
                    },
                    {
                        key: 'senha2',
                        type: 'input',
                        templateOptions: {
                            label: 'Repita a senha',
                            maxlength: 32,
                            minlength: 3,
                            required: true,
                            type: 'password',
                            icon: 'fas fa-lock'
                        }
                    }
                ];

                $ctrl.setNewPassword = function () {

                    var senha1 = $ctrl.model.senha1;
                    var senha2 = $ctrl.model.senha2;

                    if (!senha1 || !senha2 || senha1 != senha2) {
                        alertFactory.error('Por favor, informe as senhas corretamente e iguais...');
                        return;
                    }

                    blockUiFactory.start();

                    firebaseProvider.auth.confirmPasswordReset($ctrl.parms.oobCode, senha1).then(function () {
                        blockUiFactory.stop();
                        alertFactory.success('Senha atualizada com sucesso...').then(function () {
                            $uibModalInstance.close();
                        })
                    }).catch(function (error) {
                        blockUiFactory.stop();
                        alertFactory.error(firebaseAuthMessages[error.code]);
                    });

                };
            })

        .factory('newPasswordFactory',

            function (
                $q,
                $uibModal
            ) {

                var showModal = function (parms) {
                    return $q(function (resolve, reject) {
                        var modal = $uibModal.open({
                            windowClass: 'new-password-modal',
                            templateUrl: 'new-password/new-password.html',
                            controller: 'newPasswordController',
                            controllerAs: '$ctrl',
                            backdrop: false,
                            resolve: {
                                parms: function () {
                                    return parms;
                                }
                            }
                        });

                        modal.result.then(function (value) {
                            resolve(value);
                        }, function () {
                            console.info('rejected!');
                            reject();
                        });

                    })
                }

                var show = function (parms) {
                    return $q(function (resolve, reject) {
                        showModal(parms).then(function (e) {
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

})();

export default ngModule;
