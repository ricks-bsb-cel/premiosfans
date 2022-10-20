'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.chaves-pix.add', [])

    .controller('chavesPixAddController',
        function (
            $uibModalInstance,
            alertFactory,
            contasService,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            delete data.idEmpresa_reference;

            $ctrl.data.type = $ctrl.data.type || 'aleatorio';

            $ctrl.fields = [
                {
                    key: 'idEmpresa',
                    templateOptions: {
                        label: 'Empresa',
                        type: 'text',
                        required: true
                    },
                    type: 'empresa',
                    className: 'col-12'
                },
                {
                    key: 'idConta',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Conta'
                    },
                    type: 'ng-selector-contas'
                },
                {
                    key: 'type',
                    templateOptions: {
                        label: 'Tipo de Chave',
                        type: 'text',
                        required: true,
                        defaultValue: 'aleatorio'
                    },
                    type: 'ng-selector-tipo-chave-pix',
                    className: 'col-12'
                },
                {
                    key: 'chave',
                    templateOptions: {
                        label: 'Chave (CPF)'
                    },
                    type: 'cpf',
                    className: 'col-12',
                    hideExpression: function () {
                        return $ctrl.data.type !== 'cpf';
                    }
                },
                {
                    key: 'chave',
                    templateOptions: {
                        label: 'Chave (CNPJ)'
                    },
                    type: 'cnpj',
                    className: 'col-12',
                    hideExpression: function () {
                        return $ctrl.data.type !== 'cnpj';
                    }
                },
                {
                    key: 'chave',
                    templateOptions: {
                        label: 'Chave (eMail)'
                    },
                    type: 'email',
                    className: 'col-12',
                    hideExpression: function () {
                        return $ctrl.data.type !== 'email';
                    }
                },
                {
                    key: 'chave',
                    templateOptions: {
                        label: 'Chave (Celular)'
                    },
                    type: 'celular',
                    className: 'col-12',
                    hideExpression: function () {
                        return $ctrl.data.type !== 'celular';
                    }
                }
            ];

            $ctrl.ok = function () {

                contasService.createPixKey({
                    data: {
                        idEmpresa: $ctrl.data.idEmpresa,
                        idConta: $ctrl.data.idConta,
                        tipo: $ctrl.data.type,
                        chave: $ctrl.data.chave
                    },
                    success: response => {
                        $uibModalInstance.close();
                    },
                    error: _ => {

                    }
                })

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('chavesPixAddFactory',

        function (
            $q,
            $uibModal
        ) {

            const showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'chaves-pix-add-modal',
                        templateUrl: 'chaves-pix/directives/add/add.html',
                        controller: 'chavesPixAddController',
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

            const add = function (original) {

                var toEdit = angular.copy(original || {});

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
                add: add
            };

            return factory;
        }
    );

export default ngModule;
