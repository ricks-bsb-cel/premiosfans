'use strict';

let ngModule;

ngModule = angular.module('directives.cartos-admin.directives.edit-service-user-credential', [])

    .controller('cartosAdminEditServiceUserCredentialController',
        function (
            $uibModalInstance,
            alertFactory,
            collectionCartosServiceUserCredentials,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
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
                    templateOptions: {
                        label: 'Descrição',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 60
                    },
                    type: 'input',
                    className: 'col-12'
                }
            ];

            $ctrl.ok = function () {
                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionCartosServiceUserCredentials.saveAlias($ctrl.data)
                    .then(success => {
                        $uibModalInstance.close(success);
                    })

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('cartosAdminEditServiceUserCredentialFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'cartos-admin-edit-service-user-credential-modal',
                        templateUrl: 'cartos-admin/directives/edit-service-user-credential/edit.html',
                        controller: 'cartosAdminEditServiceUserCredentialController',
                        controllerAs: '$ctrl',
                        size: 'md',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return e;
                            }
                        }
                    });

                    modal.result.then(function (data) {
                        resolve(data);
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
                            original = updated;
                            resolve(original);
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
