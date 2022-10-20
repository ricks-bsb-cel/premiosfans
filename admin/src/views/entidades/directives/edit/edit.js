'use strict';

const ngModule = angular.module('view.entidades.edit', [])

    .controller('entidadesEditController',
        function (
            $uibModalInstance,
            alertFactory,
            entidadesFactory,
            collectionEntidades,
            data,
            type
        ) {

            var $ctrl = this;

            $ctrl.ready = false;
            $ctrl.error = false;
            $ctrl.data = data;
            $ctrl.type = type;
            $ctrl.config = null;
            $ctrl.forms = null;

            const loadFields = config => {

                $ctrl.forms = {
                    main: {
                        fields: [
                            {
                                key: 'cpfcnpj',
                                type: 'cpf',
                                className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xl-3',
                                templateOptions: {
                                    label: 'CPF',
                                    type: 'text',
                                    required: true
                                },
                                hideExpression: function () {
                                    return !(config.type.pf && !config.type.pj);
                                }
                            },
                            {
                                key: 'cpfcnpj',
                                type: 'cnpj',
                                className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xl-3',
                                templateOptions: {
                                    label: 'CNPJ',
                                    type: 'text',
                                    required: true
                                },
                                hideExpression: function () {
                                    return !(!config.type.pf && config.type.pj);
                                }
                            },
                            {
                                key: 'cpfcnpj',
                                type: 'cpfcnpj',
                                className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xl-3',
                                templateOptions: {
                                    label: 'CPF/CNPJ',
                                    type: 'text',
                                    required: true
                                },
                                hideExpression: function () {
                                    return !(config.type.pf && config.type.pj);
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
                                className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
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
                        ],
                        form: null
                    },
                    contatos:
                    {
                        fields: [
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
                                    label: 'Email Principal',
                                    type: 'text',
                                    required: false,
                                    type: 'email'
                                },
                                type: 'input'
                            }
                        ],
                        form: null
                    },
                    documentos: {
                        fields: [],
                        form: null
                    }
                };

                if (config.type.pf) {
                    $ctrl.forms.documentos.fields.push({
                        key: 'dtNascimento',
                        templateOptions: {
                            label: 'Data de Nascimento',
                            required: true
                        },
                        type: 'data',
                        className: 'col-xs-12 col-sm-12 col-md-12 col-lg-9 col-xl-9'
                    });
                }

            }

            entidadesFactory.getConfig($ctrl.type)
                .then(config => {
                    loadFields(config);
                    $ctrl.config = config;
                    $ctrl.ready = true;
                })
                .catch(e => {
                    console.error(e);
                })

            $ctrl.ok = function () {
                if ($ctrl.forms.main.$invalid ||
                    $ctrl.forms.contatos.$invalid ||
                    ($ctrl.forms.documentos.fields.length && $ctrl.forms.documentos.$invalid)
                ) {
                    alertFactory.error("Verifique os campos obrigatórios e tente novamente.", "Erro no formulário");
                    return;
                }

                collectionEntidades.save($ctrl.data, $ctrl.type)
                    .then(function () {
                        $uibModalInstance.close($ctrl.data);
                    });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('entidadesEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (d, t) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'entidades-edit-modal',
                        templateUrl: 'entidades/directives/edit/edit.html',
                        controller: 'entidadesEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
                        resolve: {
                            data: function () { return d; },
                            type: function () { return t; }
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

            var edit = function (original, type) {
                var toEdit = angular.copy(original || {});

                return $q((resolve, reject) => {
                    showModal(toEdit, type)
                        .then(updated => {
                            original = updated;
                            resolve(original);
                        })
                        .catch(function () {
                            reject();
                        })
                })
            }

            return {
                edit: edit
            };;
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