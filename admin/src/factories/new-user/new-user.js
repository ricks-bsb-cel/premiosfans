'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('factories.new-user', [])

    .controller('newUserController',
        function (
            $uibModalInstance,
            alertFactory,
            blockUiFactory,
            firebaseProvider,
            firebaseAuthMessages,
        ) {

            var $ctrl = this;

            $ctrl.ready = false;
            $ctrl.error = false;

            $ctrl.fields = [
                {
                    key: 'email',
                    type: 'input',
                    className: 'col-12 capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        maxlength: 128,
                        minlength: 3,
                        required: true,
                        type: 'email',
                        icon: 'fas fa-envelope'
                    },

                },
                {
                    key: 'senha1',
                    type: 'input',
                    className: 'col-12',
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
                    className: 'col-12',
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

            $ctrl.createAccess = function () {

                var email = $ctrl.model.email;
                var senha1 = $ctrl.model.senha1;
                var senha2 = $ctrl.model.senha2;

                if ($ctrl.form.$invalid || !email || !email.includes("@") || !senha1 || !senha2 || senha1 != senha2) {
                    alertFactory.error('As senhas não são idênticas...');
                    return;
                }

                alertFactory.yesno('Tem certeza que deseja criar seu acesso com este email?', email).then(function () {
                    blockUiFactory.start();
                    firebaseProvider.auth.createUserWithEmailAndPassword(email, senha1)
                        .then(() => {
                            window.location.reload();
                        }).catch(function (e) {
                            blockUiFactory.stop();
                            alertFactory.error(firebaseAuthMessages[e.code]).then(function () {
                                if (e.code == 'auth/email-already-in-use') {
                                    $uibModalInstance.close();
                                }
                            })
                        })

                })

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('newUserFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function () {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'new-user-modal',
                        templateUrl: 'new-user/new-user.html',
                        controller: 'newUserController',
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

            var create = function (e) {
                return $q(function (resolve, reject) {
                    showModal().then(function (e) {
                        resolve(e);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            var factory = {
                create: create
            };

            return factory;
        }
    );

export default ngModule;
