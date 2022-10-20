'use strict';

const ngModule = angular.module('view.cobrancas.edit', [])

    .controller('cobrancasEditController',
        function (
            appFirestoreHelper,
            $uibModalInstance,
            collectionCobrancas,
            alertFactory,
            cliente,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.data = appFirestoreHelper.removeReferences(data);

            if (cliente) {
                $ctrl.data.idCliente = cliente.id;
            }

            $ctrl.fields = [
                {
                    key: 'idCliente',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Cliente',
                        required: true
                    },
                    type: 'ng-selector-cliente'
                },

                {
                    key: 'idContrato',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Contrato',
                        required: true
                    },
                    data: {
                        idClienteField: 'idCliente',
                        idPlanoField: 'idPlano'
                    },
                    defaultValue: null,
                    type: 'ng-selector-contrato'
                },

                {
                    key: 'idPlano',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Plano',
                        // required: "model.idContrato !== 'avulso'"
                        // disabled: $ctrl.data.idContrato !== 'avulso'
                    },
                    type: 'ng-selector-plano',
                    expressionProperties: {
                        "templateOptions.required": "model.idContrato !== 'avulso'",
                        "templateOptions.disabled": "model.idContrato !== 'avulso'"
                    }
                },

                {
                    key: 'valor',
                    templateOptions: {
                        label: 'Valor',
                        required: true,
                    },
                    type: 'reais',
                    className: 'col-6'
                },
                {
                    key: 'dtVencimento',
                    templateOptions: {
                        label: 'Vencimento',
                        required: true,
                    },
                    type: 'data',
                    className: 'col-6'
                },
                {
                    key: 'msgBoleto',
                    type: 'textarea',
                    templateOptions: {
                        label: 'Mensagem adicional boleto',
                        required: false
                    },
                    className: 'col-12'
                },
                {
                    key: 'obs',
                    type: 'textarea',
                    templateOptions: {
                        label: 'Observações'
                    },
                    className: 'col-12'
                }
            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionCobrancas.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('cobrancasEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e, cliente) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'cobrancas-edit-modal',
                        templateUrl: 'cobrancas/directives/edit/edit.html',
                        controller: 'cobrancasEditController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return e;
                            },
                            cliente: function () {
                                return cliente;
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

            var edit = function (original, cliente) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit, cliente).then(function (updated) {
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
