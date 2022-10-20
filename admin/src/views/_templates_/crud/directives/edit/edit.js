'use strict';

let ngModule = angular.module('view.crud.edit', [])

    .controller('crudEditController',
        function (
            $uibModalInstance,
            collectionCrud,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;
            $ctrl.edit = !!(data && data.id);

            $ctrl.fields = [
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
                    key: 'situacao',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Situação'
                    },
                    type: 'ng-selector-tipo-pessoa'
                },
                {
                    key: 'repeat',
                    className: 'col-12',
                    defaultValue: 1,
                    templateOptions: {
                        label: 'Repeater',
                    },
                    type: 'integer'
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

            $ctrl.ok = _ => {
                if ($ctrl.form.$invalid || $ctrl.data.valorMinimo > $ctrl.data.valorMaximo) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionCrud.save($ctrl.data).then(_ => {
                    if (!$ctrl.edit && $ctrl.data.repeat > 1) {
                        $ctrl.data.repeat--;
                        $ctrl.ok();
                        return;
                    }

                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('crudEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'crud-edit-modal',
                        templateUrl: '_templates_/crud/directives/edit/edit.html',
                        controller: 'crudEditController',
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
