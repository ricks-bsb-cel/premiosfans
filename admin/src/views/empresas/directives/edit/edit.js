'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.empresas.edit', [])

    .controller('empresasEditController',
        function (
            $uibModalInstance,
            collectionEmpresas,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'representante_cpf',
                    type: 'cpf',
                    className: 'col-xs-12 col-sm-12 col-md-7 col-lg-7 col-xl-7',
                    templateOptions: {
                        label: 'CPF',
                        type: 'text',
                        required: true
                    },
                    ngModelElAttrs: { disabled: 'true' }
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
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
                },
                {
                    key: 'nomeFantasia',
                    templateOptions: {
                        label: 'Nome de Fantasia',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
                },
                {
                    key: 'ativo',
                    className: 'col-12',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Ativa',
                    },
                    type: 'custom-checkbox'
                }

            ];

            $ctrl.contatos = [
                {
                    key: 'email',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-7 col-xl-7 capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        required: true,
                        type: 'email'
                    },
                    type: 'input',
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'celular',
                    type: 'celular',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-5 col-xl-5',
                    templateOptions: {
                        label: 'Celular',
                        required: true
                    },
                    ngModelElAttrs: { disabled: 'true' }
                }
            ];

            $ctrl.ok = function () {
                collectionEmpresas.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('empresasEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (data) {
                return $q((resolve, reject) => {

                    const modal = $uibModal.open({
                        windowClass: 'empresas-edit-modal',
                        templateUrl: 'empresas/directives/edit/edit.html',
                        controller: 'empresasEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
                        resolve: {
                            data: function () {
                                return data;
                            }
                        }
                    });

                    modal.result
                        .then(data => {
                            resolve(data);
                        }, _ => {
                            reject();
                        });

                })
            }

            var edit = function (original) {

                var toEdit = angular.copy(original);

                return $q((resolve, reject) => {
                    showModal(toEdit)
                        .then(updated => {
                            original = updated;
                            resolve(original);
                        })
                        .catch(e => {
                            reject(e);
                        })
                })
            }

            return {
                edit: edit
            };
        }
    );

export default ngModule;
