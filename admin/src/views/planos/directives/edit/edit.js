'use strict';

/*
One pill makes you larger
And one pill makes you small,
And the ones that mother gives you
Don't do anything at all.
*/

let ngModule;

ngModule = angular.module('view.planos.edit', [])

    .controller('planosEditController',
        function (
            $uibModalInstance,
            collectionPlanos,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'nome',
                    templateOptions: {
                        label: 'Nome do Plano',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'sigla',
                    templateOptions: {
                        label: 'Sigla do Plano',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 16
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'valorMinimo',
                    templateOptions: {
                        label: 'Valor Mínimo',
                        required: true,
                    },
                    type: 'reais',
                    className: 'col-6'
                },
                {
                    key: 'valorMaximo',
                    templateOptions: {
                        label: 'Valor Máximo',
                        required: true,
                    },
                    type: 'reais',
                    className: 'col-6'
                },
                {
                    key: 'msgBoleto',
                    type: 'textarea',
                    templateOptions: {
                        label: 'Mensagem a ser apresentada no boleto'
                    },
                    className: 'col-12'
                },
                {
                    key: 'ativo',
                    className: 'col-12',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Ativo',
                    },
                    type: 'custom-checkbox'
                }

            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid || $ctrl.data.valorMinimo > $ctrl.data.valorMaximo) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionPlanos.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('planosEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'planos-edit-modal',
                        templateUrl: 'planos/directives/edit/edit.html',
                        controller: 'planosEditController',
                        controllerAs: '$ctrl',
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
