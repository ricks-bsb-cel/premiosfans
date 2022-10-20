'use strict';

let ngModule = angular.module('view.produtos.edit', [])

    .controller('produtosEditController',
        function (
            $uibModalInstance,
            collectionProdutos,
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
                        label: 'Nome do Produto ou Serviço',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'codigo',
                    templateOptions: {
                        label: 'Código',
                        type: 'text',
                        required: false
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'descricao',
                    type: 'textarea',
                    templateOptions: {
                        label: 'Descrição (opcional)'
                    },
                    className: 'col-12'
                },
                {
                    key: 'valor',
                    templateOptions: {
                        label: 'Valor',
                        required: true,
                    },
                    type: 'reais',
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

                if ($ctrl.form.$invalid || $ctrl.data.valor <= 0) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionProdutos.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('produtosEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'produtos-edit-modal',
                        templateUrl: 'produtos/directives/edit/edit.html',
                        controller: 'produtosEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        resolve: {
                            data: function () { return e; }
                        }
                    });

                    modal.result
                        .then(function (data) {
                            resolve(data);
                        }, function () {
                            reject();
                        });

                })
            }

            var edit = function (original) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit)
                        .then(function (updated) {
                            original = updated;
                            resolve(original);
                        }).catch(function () {
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
