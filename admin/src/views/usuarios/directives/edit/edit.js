'use strict';

/*
Will the wind ever remember
The names it has blown in the past?
And with this crutch, its old age and its wisdom
It whispers, "No, this will be the last"
*/

import angular from 'angular';
import blockperfilEmpresas from '../perfil-empresa/perfil-empresa';

let ngModule = angular.module('view.usuarios.edit', [
    blockperfilEmpresas.name
])

    .controller('usuarioEditController',
        function (
            $uibModalInstance,
            collectionUserProfile,
            alertFactory,
            appAuthHelper,
            doc
        ) {

            var $ctrl = this;

            $ctrl.ready = false;
            $ctrl.error = false;
            $ctrl.allowProfile = true;

            $ctrl.data = angular.copy(doc) || {};

            $ctrl.fields = [
                {
                    key: 'id',
                    templateOptions: {
                        label: 'ID do Usuário',
                        type: 'text',
                        required: true
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 uid',
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'email',
                    className: 'col-12capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        required: true,
                        type: 'email'
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'phoneNumber',
                    type: 'mask-number',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
                    templateOptions: {
                        label: 'Phone Number',
                        type: 'text'
                    }
                },
                {
                    key: 'displayName',
                    templateOptions: {
                        label: 'Display Name',
                        type: 'text',
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
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

            $ctrl.apiKeyFields = [
                {
                    key: 'apikey',
                    templateOptions: {
                        label: 'Api Key',
                        type: 'text'
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12 api-key'
                },
                {
                    key: 'apiDirectCall',
                    defaultValue: false,
                    templateOptions: {
                        title: 'Direct Call',
                    },
                    type: 'custom-checkbox',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
                }
            ];

            $ctrl.ok = function () {

                var error = false;

                if ($ctrl.form.$invalid) {
                    alertFactory.error('Dados inválidos... Verifique!')
                    return;
                }

                collectionUserProfile.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('usuarioEditFactory',

        function (
            $q,
            $uibModal
        ) {

            const showModal = function (doc) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'usuario-edit-modal',
                        templateUrl: 'usuarios/directives/edit/edit.html',
                        controller: 'usuarioEditController',
                        controllerAs: '$ctrl',
                        size: 'xl',
                        backdrop: false,
                        resolve: {
                            doc: function () {
                                return doc;
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

            const edit = function (doc) {
                var toEdit = angular.copy(doc || {});
                return $q(function (resolve, reject) {
                    showModal(toEdit).then(function (updated) {
                        resolve(updated);
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
