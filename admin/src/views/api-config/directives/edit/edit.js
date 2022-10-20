'use strict';

let ngModule = angular.module('view.api-config.edit', [])

    .controller('apiConfigEditController',
        function (
            $uibModalInstance,
            collectionApiConfig,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data || {};

            delete $ctrl.data.idEmpresa_reference;

            $ctrl.fields = [
                {
                    key: 'idEmpresa',
                    className: 'col-12',
                    templateOptions: {
                        required: true
                    },
                    type: 'ng-selector-empresa'
                },
                {
                    key: 'descricao',
                    templateOptions: {
                        label: 'Descrição',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'sandbox',
                    className: 'col-4',
                    defaultValue: true,
                    templateOptions: {
                        title: 'SandBox (Modo de teste)',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'gatewayOnly',
                    className: 'col-4',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Gateway Only',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'ativo',
                    className: 'col-4',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Ativo',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'apiKey',
                    templateOptions: {
                        label: 'Chave da API'
                    },
                    type: 'input',
                    ngModelElAttrs: { 
                        disabled: 'true'
                     },
                    className: 'col-12 id-api',
					hideExpression: '!model.apiKey',
                },
            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid || $ctrl.data.valorMinimo > $ctrl.data.valorMaximo) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionApiConfig.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('apiConfigEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'api-config-edit-modal',
                        templateUrl: 'api-config/directives/edit/edit.html',
                        controller: 'apiConfigEditController',
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

                var toEdit = angular.copy(original);

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
