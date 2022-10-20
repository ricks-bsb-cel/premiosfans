'use strict';

import angular from "angular";

let ngModule = angular.module('directives.simulador-cobrancas', [])

    .controller('simuladorCobrancasController',
        function (
            $scope,
            appAuthHelper,
            collectionAdmConfigPath,
            globalFactory,
            $timeout
        ) {

            $scope.ready = false;
            $scope.titles = null;
            $scope.cobrancas = [];
            $scope.meses = 6;

            let refreshTimeout;

            const showTitles = _ => {
                collectionAdmConfigPath.getById('rlbUboVFont6Y6Z62UMU')
                    .then(result => {
                        $timeout(_ => {
                            $scope.titles = result;
                        })
                    })
            }

            const calcDtVencimento = (dia, mes, ano, addMonths) => {

                let dtVencimento,
                    d = angular.copy(dia),
                    dtRef = moment({ year: ano, month: mes - 1, day: 1, hour: 0, minute: 0, second: 0, millisecond: 0 });

                dtRef.add(addMonths, 'month');

                dtVencimento = moment(dtRef);
                dtVencimento.set("date", d); // Se o dia não existir no mês, o Moment manda para o dia 1º do próximo mês

                while (dtRef.month() !== dtVencimento.month()) {
                    d--;
                    dtVencimento = moment(dtRef);
                    dtVencimento.set("date", d);
                }

                return dtVencimento;
            }

            const isExpanded = i => {
                if (document.querySelector(`.simulador-cobrancas tr[data-master-index="${i}"]`)) {
                    return angular.element(document.querySelector(`.simulador-cobrancas tr[data-master-index="${i}"]`)).attr('aria-expanded') === 'true';
                } else {
                    return false;
                }
            }

            const refresh = _ => {
                if (
                    !$scope.contrato.inicioContrato_mes ||
                    !$scope.contrato.inicioContrato_ano ||
                    !$scope.contrato.diaMesCobranca ||
                    !$scope.contrato.produtos ||
                    !$scope.contrato.produtos.length
                ) {
                    return;
                }

                const guid = globalFactory.guid();

                for (let m = 0; m < $scope.meses; m++) {
                    const dtVencimento = calcDtVencimento(
                        $scope.contrato.diaMesCobranca,
                        $scope.contrato.inicioContrato_mes,
                        $scope.contrato.inicioContrato_ano,
                        m
                    );

                    let parcela = {
                        dtVencimento_ymd: dtVencimento.format("YYYY-MM-DD"),
                        dtVencimento_dmy: dtVencimento.format("DD/MM/YYYY"),
                        produtos: [],
                        valor: 0,
                        parcela: m + 1,
                        guid: guid,
                        isExpanded: isExpanded(m)
                    }

                    $scope.contrato.produtos.forEach(p => {
                        if (p.tipo === 'am' || m < p.qtd) {
                            parcela.valor += p.valor;
                            parcela.produtos.push(p);
                        }
                    })

                    if (m <= ($scope.cobrancas.length - 1)) {
                        $scope.cobrancas[m] = parcela;
                    } else {
                        $scope.cobrancas.push(parcela);
                    }
                }

                $scope.cobrancas = $scope.cobrancas.filter(f => {
                    return f.guid === guid && f.produtos.length;
                })

            }

            const callRefresh = _ => {
                if (refreshTimeout) {
                    $timeout.cancel(refreshTimeout);
                    refreshTimeout = null;
                }

                refreshTimeout = $timeout(_ => {
                    refresh();
                }, 1000)
            }

            const init = _ => {
                showTitles();

                $scope.$watch('contrato', function () {
                    callRefresh();
                }, true);

                $scope.$watch('meses', function () {
                    refresh();
                })
            }

            appAuthHelper.ready()
                .then(_ => {
                    init();
                    console.info('simulador-cobrancas ready')
                })

        })

    .directive('simuladorCobrancas', function () {
        return {
            restrict: 'E',
            templateUrl: 'simulador-cobrancas/simulador-cobrancas.html',
            controller: 'simuladorCobrancasController',
            scope: {
                contrato: "=",
            }
        };
    });

export default ngModule;
