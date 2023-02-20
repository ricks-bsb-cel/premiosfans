'use strict';

let ngModule;

ngModule = angular.module('directives.cartos-admin.directives.new-account', [])

    .controller('cartosAdminNewAccountController',
        function (
            $uibModalInstance,
            alertFactory,
            userAccount
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.userAccount = userAccount;

            $ctrl.fields = [
                {
                    template: '<h5>Usuário Principal</h5>'
                },
                {
                    key: 'cpf',
                    type: 'cpf',
                    className: 'col-12',
                    templateOptions: {
                        label: 'CPF'
                    },
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'alias',
                    type: 'input',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Apelido'
                    },
                    ngModelElAttrs: { disabled: 'true' }
                },

            ];

            $ctrl.ok = function () {
                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                $uibModalInstance.close(success);

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('cartosAdminNewAccountFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'cartos-admin-new-account-modal',
                        templateUrl: 'cartos-admin/directives/new-account/edit.html',
                        controller: 'cartosAdminNewAccountController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            userAccount: function () {
                                return e;
                            }
                        }
                    });

                    modal.result.then(function (userAccount) {
                        resolve(userAccount);
                    }, function () {
                        reject();
                    });

                })
            }

            const edit = function (original) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit)
                        .then(function (updated) {
                            resolve(updated);
                        })
                        .catch(function () {
                            reject();
                        })
                })
            }

            return {
                edit: edit
            };
        }
    );

export default ngModule;
