'use strict';

let ngModule = angular.module('view.planos.generate-fake-data', [])

    .controller('generateFakeDataController',
        function (
            $uibModalInstance,
            appAuthHelper,
            appFirestoreHelper,
            plano,
            globalFactory,
            collectionEmpresas,
            collectionContratos,
            collectionClientes,
            clienteService,
            alertFactory,
            blockUiFactory,
            $q
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.plano = plano;

            $ctrl.msg = null;

            $ctrl.data = {
                idPlano: plano.id,
                valor: plano.valorMinimo,
                diaMes: 0
            };

            $ctrl.fields = [
                {
                    key: 'idPlano',
                    templateOptions: {
                        label: 'Plano',
                        required: true
                    },
                    type: 'ng-selector-plano',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-9 col-xs-9',
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'valor',
                    templateOptions: {
                        label: 'Valor do contrato',
                        required: true,
                    },
                    type: 'reais',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xs-3'
                },
                {
                    key: 'periodoParcela',
                    templateOptions: {
                        label: 'Período da Parcela',
                        required: true
                    },
                    defaultValue: "mensal",
                    type: 'ng-selector-periodo-parcela',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-9 col-xs-9',
                    ngModelElAttrs: { disabled: 'true' }
                },
                {
                    key: 'diaMes',
                    templateOptions: {
                        label: 'Dia do Mês',
                        required: true,
                    },
                    type: 'integer',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xs-3'
                },
                {
                    key: 'dtInicioContrato',
                    templateOptions: {
                        label: 'Data de Início',
                        required: true
                    },
                    type: 'data',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xs-4'
                },
                {
                    key: 'qtdParcelas',
                    templateOptions: {
                        label: 'Qtd. Parcelas',
                        required: true
                    },
                    type: 'integer',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-5 col-xs-5'
                },
                {
                    key: 'qtdContratos',
                    templateOptions: {
                        label: 'Registros',
                        required: true,
                    },
                    type: 'integer',
                    className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xs-3'
                }
            ];

            $ctrl.ok = _ => {

                if ($ctrl.form.$invalid) {
                    alertFactory.error("Wow! Verifique os dados...");
                    return;
                }

                const runGenerate = _ => {

                    $ctrl.data.qtdContratos--;

                    generate()
                        .then(contrato => {
                            return appFirestoreHelper.getDoc(contrato.idCliente_reference);
                        })

                        .then(cliente => {

                            $ctrl.msg = cliente.cpf_formatted + ': ' + cliente.nome;

                            if ($ctrl.data.qtdContratos > 0) {
                                runGenerate();
                            } else {
                                $ctrl.msg = null;
                                blockUiFactory.stop();
                            }

                        })

                        .catch(e => {
                            blockUiFactory.stop();
                            alertFactory.error(e);
                        })
                }

                alertFactory.yesno('Gerar ' + $ctrl.data.qtdContratos + ' contratos?')
                    .then(_ => {
                        blockUiFactory.start();
                        runGenerate();
                    });

            }

            const generate = function () {
                return $q(function (resolve, reject) {
                    generateCliente()
                        .then(cliente => {
                            return generateContrato(cliente);
                        })
                        .then(contrato => {
                            return resolve(contrato);
                        })
                        .catch(e => {
                            return reject(e);
                        })
                })
            }

            const generateContrato = function (cliente) {
                return $q(function (resolve, reject) {

                    var contrato = angular.copy($ctrl.data);

                    contrato.isFakeData = true;
                    contrato.idCliente = cliente.id;
                    contrato.idEmpresa = cliente.idEmpresa;

                    collectionContratos.save(contrato)
                        .then(function (result) {
                            return resolve(result);
                        }).catch(e => {
                            return reject(e);
                        })

                })
            }

            const generateCliente = _ => {
                return $q((resolve, reject) => {

                    clienteService.fakeData({
                        success: data => {

                            var cpf = globalFactory.randomCpf();
                            var celular = globalFactory.formatPhoneNumber('5' + data.phone);

                            var cliente = {
                                idEmpresa: appAuthHelper.profile.user.idEmpresa,

                                celular_formatted: celular,
                                celular: globalFactory.onlyNumbers(celular),
                                celular_int: '55' + globalFactory.onlyNumbers(celular),
                                celular_intplus: '+55' + globalFactory.onlyNumbers(celular),

                                cpfcnpj: globalFactory.onlyNumbers(cpf),
                                cpfcnpj_formatted: cpf,
                                cpfcnpj_type: 'PF',

                                cpf: globalFactory.onlyNumbers(cpf),
                                cpf_formatted: cpf,

                                cnpj: null,
                                cnpj_formatted: null,

                                nome: data.name.first + ' ' + data.name.last,
                                email: data.email,
                                isFakeData: true
                            };

                            collectionClientes.save(cliente)
                                .then(result => {
                                    return resolve(result);
                                }).catch(e => {
                                    console.error(e);
                                    return reject(e);
                                })

                        }
                    })
                })
            }

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };

            appAuthHelper.ready()
                .then(_ => {
                    return collectionEmpresas.collection.getDoc(appAuthHelper.profile.user.idEmpresa);
                })

                .then(empresa => {
                    const hoje = appFirestoreHelper.currentTimestamp();
                    const momentHoje = moment(hoje.toDate()).add(empresa.diasGeracaoCobranca, 'days');
                    $ctrl.data.diaMes = momentHoje.date();
                })


        })

    .factory('generateFakeDataFactory',
        function (
            $q,
            $uibModal
        ) {

            const showModal = function (plano) {

                return $q(function (resolve, reject) {

                    var modal = $uibModal.open({
                        windowClass: 'generate-fake-data-modal',
                        templateUrl: 'planos/directives/generateFakeData/generateFakeData.html',
                        controller: 'generateFakeDataController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            plano: function () {
                                return plano;
                            }
                        }
                    });

                    modal.result.then(function (data) {
                        return resolve(data);
                    }, function () {
                        return reject();
                    });

                })
            }

            const show = function (plano) {

                return $q(function (resolve, reject) {
                    showModal(plano || null).then(function () {
                        return resolve();
                    }).catch(function () {
                        return reject();
                    })
                })
            }

            var factory = {
                show: show
            };

            return factory;
        }
    );

export default ngModule;
