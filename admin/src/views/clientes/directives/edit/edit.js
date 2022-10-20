'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.clientes.edit', [])

    .controller('clientesEditController',
        function (
            $uibModalInstance,
            collectionClientes,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            delete data.idEmpresa_reference;

            $ctrl.fields = [
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
                }
            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error("Verifique os campos obrigatórios e tente novamente.", "Erro no formulário");
                    return;
                }

                collectionClientes.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('clientesEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'clientes-edit-modal',
                        templateUrl: 'clientes/directives/edit/edit.html',
                        controller: 'clientesEditController',
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
