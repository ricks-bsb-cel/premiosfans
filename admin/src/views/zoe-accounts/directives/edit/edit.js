'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.zoe-accounts.edit', [])

    .controller('zoeAccountsEditController',
        function (
            $uibModalInstance,
            collectionZoeAccounts,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'idEmpresa',
                    templateOptions: {
                        label: 'Empresa',
                        type: 'text',
                        required: true
                    },
                    type: 'empresa',
                    className: 'col-12'
                },
                {
                    key: 'cpfcnpj',
                    type: 'cpfcnpj',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
                    templateOptions: {
                        label: 'CPF/CNPJ',
                        type: 'text',
                        required: true
                    }
                },
                {
                    key: 'nome',
                    templateOptions: {
                        label: 'Nome',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xl-8',
                }
            ];

            if ($ctrl.data.id) {
                $ctrl.fields[1].ngModelElAttrs = { disabled: 'true' };
            }

            $ctrl.contatos = [
                {
                    key: 'celular',
                    type: 'celular',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
                    templateOptions: {
                        label: 'Celular/Whatsapp',
                        required: false
                    }
                },
                {
                    key: 'email',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-7 col-xl-7 capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        required: false,
                        type: 'email'
                    },
                    type: 'input'
                },
                {
                    key: 'ignorarEndereco',
                    className: 'col-12',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Ignorar Endereço',
                    },
                    type: 'custom-checkbox'
                }

            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error("Verifique os campos obrigatórios e tente novamente.", "Erro no formulário");
                    return;
                }

                collectionZoeAccounts.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('zoeAccountsEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'zoe-accounts-edit-modal',
                        templateUrl: 'zoe-accounts/directives/edit/edit.html',
                        controller: 'zoeAccountsEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
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

            var edit = function (original) {

                var toEdit = angular.copy(original || {});

                return $q(function (resolve, reject) {
                    showModal(toEdit).then(function (updated) {
                        original = updated;
                        resolve(original);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            var factory = {
                edit: edit
            };

            return factory;
        }
    );

export default ngModule;
