'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

ngModule = angular.module('view.funcionarios.edit', [])

    .controller('funcionariosEditController',
        function (
            $uibModalInstance,
            folhaService,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            delete data.idEmpresa_reference;
            delete data.uidUsuarioAlteracao_reference;
            delete data.uidUsuarioInclusao_reference;

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
                    key: 'cpf',
                    type: 'cpf',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xl-3',
                    templateOptions: {
                        label: 'CPF',
                        type: 'text',
                        required: true
                    }
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
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-9 col-xl-9',
                },
                {
                    key: 'dtNascimento',
                    templateOptions: {
                        label: 'Data de Nascimento',
                        required: true
                    },
                    type: 'data',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-9 col-xl-9'
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

            if ($ctrl.data.id) {
                $ctrl.fields[1].ngModelElAttrs = { disabled: 'true' };
            }

            $ctrl.contatos = [
                {
                    key: 'celular',
                    type: 'celular',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
                    templateOptions: {
                        label: 'Celular/Whatsapp',
                        required: false
                    }
                },
                {
                    key: 'email',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xl-8 capitalize-email',
                    templateOptions: {
                        label: 'Email',
                        type: 'text',
                        required: false,
                        type: 'email'
                    },
                    type: 'input'
                }
            ];

            $ctrl.ok = function () {

                if ($ctrl.form.$invalid) {
                    alertFactory.error("Verifique os campos obrigatórios e tente novamente.", "Erro no formulário");
                    return;
                }

                folhaService.setFuncionario({
                    data: $ctrl.data,
                    success: data => {
                        $uibModalInstance.close(data);
                    },
                    error: e => {
                        debugger;
                    }
                })

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('funcionariosEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'funcionarios-edit-modal',
                        templateUrl: 'folha/funcionarios/directives/edit/edit.html',
                        controller: 'funcionariosEditController',
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
                edit: edit
            };

            return factory;
        }
    );

export default ngModule;


/*
#tbt:
Você como lider:
Se você gritar com seu time vai acontecer duas coisas:
Parte do time vai correr pra você (afinal, você está gritando com eles!) e
parte dele vai correr de você.
E os que correrem de você não vão voltar mais...
Mas aí você vai pensar... não tem problema. Com o salário desse cara eu contrato 3 estagiários...
*/