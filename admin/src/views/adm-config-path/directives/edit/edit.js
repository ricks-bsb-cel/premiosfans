'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.admConfigPath.edit', [])

    .controller('admConfigPathEditController',
        function (
            $uibModalInstance,
            collectionAdmConfigPath,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'label',
                    templateOptions: {
                        label: 'Label',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-6'
                },
                {
                    key: 'href',
                    templateOptions: {
                        label: 'href',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-6'
                },
                /*
                {
                    key: 'modulo',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Módulos',
                        collection: 'admConfigModulos',
                        multiselect: true
                    },
                    type: 'ng-selector'
                },
                */
                {
                    key: 'collection',
                    templateOptions: {
                        label: 'Collection',
                        type: 'text',
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-12'
                },
                /*
                {
                    key: 'order',
                    templateOptions: {
                        label: 'Ordenação',
                        type: 'text',
                        required: true
                    },
                    type: 'integer',
                    className: 'col-12'
                },
                */
                {
                    key: 'ativo',
                    className: 'col-12',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Ativo',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'directRoute',
                    className: 'col-12',
                    defaultValue: true,
                    templateOptions: {
                        title: 'Rota direta',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'superUserOnly',
                    className: 'col-12',
                    defaultValue: false,
                    templateOptions: {
                        title: 'SuperUser Only',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'icon',
                    templateOptions: {
                        label: 'href',
                        required: true
                    },
                    type: 'fa-icon',
                    className: 'col-12'
                }
            ];

            $ctrl.ok = function () {
                collectionAdmConfigPath.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('admConfigPathEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'adm-config-path-edit-modal',
                        templateUrl: 'adm-config-path/directives/edit/edit.html',
                        controller: 'admConfigPathEditController',
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
