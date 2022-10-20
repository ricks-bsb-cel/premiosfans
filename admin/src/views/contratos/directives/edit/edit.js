'use strict';

let ngModule = angular.module('view.contratos.edit', [])

    .controller('contratosEditController',
        function (
            $uibModalInstance,
            collectionContratos,
            alertFactory,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.data = data || {
                periodoParcela: 'mensal'
            };

            delete $ctrl.data.idCliente_reference;
            delete $ctrl.data.idEmpresa_reference;
            delete $ctrl.data.idPlano_reference;

            $ctrl.forms = {
                main: {
                    fields: [
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
                            key: 'idPlano',
                            templateOptions: {
                                label: 'Plano',
                                required: true
                            },
                            type: 'ng-selector-plano',
                            className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xs-12'
                        },

                    ],
                    form: null
                },
                cobranca: {
                    fields: [
                        {
                            key: 'tipoCobranca',
                            className: 'inline',
                            type: 'ng-selector-tipo-cobranca',
                            templateOptions: {
                                label: 'Tipo de Cobrança',
                                required: true
                            }
                        },
                        {
                            key: 'mesAnoInicioContrato',
                            type: 'mask-pattern',
                            className: 'inline',
                            templateOptions: {
                                label: 'Início do Contrato (mês/ano)',
                                type: 'text',
                                mask: '99/9999',
                                required: true
                            }
                        },
                        {
                            key: 'diaMes',
                            templateOptions: {
                                label: 'Dia do Mês',
                                required: true,
                            },
                            type: 'integer',
                            className: 'inline'
                        },
                        {
                            key: 'qtdParcelas',
                            templateOptions: {
                                label: 'Quantidade de Parcelas',
                                required: true,
                            },
                            type: 'integer',
                            className: 'inline'
                        },
                    ],
                    form: null
                },
                valores: {
                    fields: [
                        {
                            key: 'valorPrincipal',
                            className: 'inline',
                            type: 'mask-number',
                            templateOptions: {
                                label: 'Valor Principal',
                                required: true
                            }
                        },
                        {
                            key: 'posVencimentoValorMulta',
                            className: 'inline',
                            type: 'mask-number',
                            templateOptions: {
                                label: 'Valor Principal',
                                required: true
                            }
                        }
                    ],
                    form: null
                },
                detalhes: {
                    fields: [
                        {
                            key: 'obs',
                            type: 'textarea',
                            templateOptions: {
                                label: 'Observações'
                            },
                            className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xs-12'
                        }
                    ],
                    form: null
                }
            };

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error('Dados inválidos... Verifique.')
                    return;
                }

                collectionContratos.save($ctrl.data)
                    .then(function () {
                        $uibModalInstance.close($ctrl.data);
                    });

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('contratosEditFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = data => {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'contratos-edit-modal',
                        templateUrl: 'contratos/directives/edit/edit.html',
                        controller: 'contratosEditController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return data;
                            }
                        }
                    });

                    modal.result.then(data => {
                        resolve(data);
                    }, function () {
                        reject();
                    });

                })
            }

            var edit = function (original) {
                var copy = angular.copy(original);
                return $q(function (resolve, reject) {
                    showModal(copy).then(updated => {
                        resolve(updated);
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
