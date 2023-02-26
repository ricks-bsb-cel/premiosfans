'use strict';

let ngModule;

ngModule = angular.module('directives.cartos-admin.directives.new-account', [])

    .controller('cartosAdminNewAccountController',
        function (
            $uibModalInstance,
            alertFactory,
            userAccount
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.userAccount = userAccount;

            const
                fieldsUser = [
                    {
                        key: 'cpf',
                        type: 'cpf',
                        templateOptions: {
                            label: 'CPF'
                        },
                        ngModelElAttrs: { disabled: 'true' },
                        className: "col-4"
                    },
                    {
                        key: 'alias',
                        type: 'input',
                        templateOptions: {
                            label: 'Apelido'
                        },
                        ngModelElAttrs: { disabled: 'true' },
                        className: "col-8"
                    },
                    {
                        key: 'soTestando',
                        type: 'image-storage-upload',
                        templateOptions: {
                            slimOptions: {
                                size: '512:512'
                            },
                            screenSize: {
                                width: '100px',
                                height: '100px'
                            }
                        }
                    }
                ],
                fieldsCompanyData = [
                    {
                        key: 'cnpj',
                        type: 'cnpj',
                        templateOptions: {
                            label: 'CNPJ da Empresa'
                        },
                        className: "col-12"
                    },
                    {
                        key: 'companyName',
                        type: 'input',
                        templateOptions: {
                            label: 'Nome Oficial da Empresa',
                            minwidth: 3,
                            maxwidth: 120,
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'tradingName',
                        type: 'input',
                        templateOptions: {
                            label: 'Nome de Fantasia',
                            minwidth: 3,
                            maxwidth: 120,
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'dateStartCompany',
                        type: 'data',
                        templateOptions: {
                            label: 'Data de Abertura da Empresa',
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'phone',
                        type: 'telefone',
                        templateOptions: {
                            label: 'Telefone/Celular',
                            required: true
                        },
                        className: "col-12"
                    }
                ],
                fieldsPersonalData = [
                    {
                        key: 'cpf',
                        type: 'cpf',
                        templateOptions: {
                            label: 'CPF do Representante',
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'name',
                        type: 'input',
                        templateOptions: {
                            label: 'Nome do Representante',
                            minwidth: 3,
                            maxwidth: 120,
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'birthdate',
                        type: 'data',
                        templateOptions: {
                            label: 'Data de Nascimento',
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'phone',
                        type: 'telefone',
                        templateOptions: {
                            label: 'Telefone/Celular',
                            required: true
                        },
                        className: "col-12"
                    }
                ],
                fieldsAddress = [
                    {
                        key: 'addressType',
                        type: 'select',
                        templateOptions: {
                            label: 'Tipo do Endereço',
                            required: true,
                            options: [
                                { name: 'PJ', value: 'PJ' },
                                { name: 'Casa', value: 'Casa' },
                                { name: 'Escritório', value: 'Escritório' },
                                { name: 'Trabalho', value: 'Trabalho' }
                            ]
                        },
                        defaultValue: 'PJ',
                        className: 'col-6'
                    },
                    {
                        key: 'postalCode',
                        type: 'mask-pattern',
                        templateOptions: {
                            label: 'CEP',
                            type: 'text',
                            mask: '99 999 999',
                            required: true
                        },
                        className: "col-6"
                    },
                    {
                        key: 'street',
                        type: 'input',
                        templateOptions: {
                            label: 'Rua, Avenida, Quadra, etc',
                            minwidth: 3,
                            maxwidth: 120,
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'number',
                        type: 'input',
                        templateOptions: {
                            label: 'Número',
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'district',
                        type: 'input',
                        templateOptions: {
                            label: 'Bairro',
                            required: true
                        },
                        className: "col-12"
                    },
                    {
                        key: 'city',
                        type: 'input',
                        templateOptions: {
                            label: 'Cidade',
                            required: true
                        },
                        className: "col-6"
                    },
                    {
                        key: 'state',
                        templateOptions: {
                            label: 'Estado',
                            type: 'text',
                            required: true
                        },
                        type: 'ng-selector-estado',
                        className: "col-6"
                    },
                    {
                        key: 'complement',
                        type: 'input',
                        templateOptions: {
                            label: 'Complemento',
                            required: true
                        },
                        className: "col-12"
                    }
                ];

            $ctrl.forms = {
                user: {
                    title: "Usuário",
                    fields: fieldsUser,
                    data: $ctrl.userAccount
                },
                empresa: {
                    title: "Empresa",
                    fields: fieldsCompanyData,
                    data: {}
                },
                empresaAddress: {
                    title: "Endereço da Empresa",
                    fields: fieldsAddress,
                    data: {}
                },
                representante: {
                    title: "Representante",
                    fields: fieldsPersonalData,
                    data: {}
                },
                representanteAddress: {
                    title: "Endereço do Representante",
                    fields: fieldsAddress,
                    data: {}
                },
            };

            $ctrl.ok = function () {
                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                $uibModalInstance.close(success);

            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('cartosAdminNewAccountFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'cartos-admin-new-account-modal',
                        templateUrl: 'cartos-admin/directives/new-account/edit.html',
                        controller: 'cartosAdminNewAccountController',
                        controllerAs: '$ctrl',
                        size: 'xl',
                        backdrop: false,
                        resolve: {
                            userAccount: function () {
                                return e;
                            }
                        }
                    });

                    modal.result.then(function (userAccount) {
                        resolve(userAccount);
                    }, function () {
                        reject();
                    });

                })
            }

            const edit = function (original) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit)
                        .then(function (updated) {
                            resolve(updated);
                        })
                        .catch(function () {
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
