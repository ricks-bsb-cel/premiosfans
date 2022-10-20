'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.vault.edit', [])

    .controller('vaultEditController',
        function (
            $uibModalInstance,
            collectionVault,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'tipo',
                    templateOptions: {
                        label: 'Tipo',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 tipo'
                },
                {
                    key: 'key',
                    templateOptions: {
                        label: 'Key',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 key'
                },
                {
                    key: 'jsonText',
                    type: 'textarea',
                    templateOptions: {
                        label: 'JSON Data',
                        require: true
                    },
                    className: 'col-12 json'
                },
                {
                    key: 'obs',
                    templateOptions: {
                        label: 'Observações',
                        type: 'text'
                    },
                    type: 'input',
                    className: 'col-12'
                }

            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error("Todos os campos são obrigatórios...");
                    return;
                }

                try {
                    $ctrl.data.json = JSON.parse($ctrl.data.jsonText);

                    collectionVault.save($ctrl.data).then(function () {
                        $uibModalInstance.close($ctrl.data);
                    });
                } catch (e) {
                    if (e.message.includes('JSON') && e.name === 'SyntaxError') {
                        alertFactory.error("O JSON está mal formado. Verifique!");
                    }
                }
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('vaultEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'vault-edit-modal',
                        templateUrl: 'vault/directives/edit/edit.html',
                        controller: 'vaultEditController',
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
