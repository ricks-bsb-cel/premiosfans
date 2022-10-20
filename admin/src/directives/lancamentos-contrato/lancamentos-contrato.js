'use strict';

import _ from "lodash";

let ngModule = angular.module('directives.lancamentos-contrato', [])

    .controller('lancamentosContratoController',
        function (
            $scope,
            appAuthHelper,
            collectionAdmConfigPath,
            collectionLancamentos,
            $timeout
        ) {

            $scope.ready = false;
            $scope.user = null;
            $scope.data = [];
            $scope.collectionLancamentos = collectionLancamentos;

            const showTitles = _ => {
                collectionAdmConfigPath.getById('rlbUboVFont6Y6Z62UMU')
                    .then(result => {
                        $timeout(_ => {
                            $scope.titles = result;
                        })
                    })
            }

            const init = _ => {
                showTitles();

                try {
                    collectionLancamentos.collection.onLoadFinish(lancamentos => {
                        setData(lancamentos);
                    })

                    collectionLancamentos.collection.startSnapshot({
                        filter: [
                            { field: "idEmpresa", operator: "==", value: $scope.user.idEmpresa },
                            { field: "guidContrato", operator: "==", value: $scope.contrato.guidContrato },
                        ]
                    });
                }
                catch (e) {
                    console.error(e);
                }
            }

            $scope.destroy = _ => {
                collectionLancamentos.collection.destroySnapshot();
            }

            const setData = lancamentos => {
                $scope.data = [];

                _.orderBy(lancamentos, ['dtVencimento'], ['asc'])
                    .forEach(d => {
                        let i = $scope.data.findIndex(f => { return f.ano === d.dtVencimento_ano && f.mes === d.dtVencimento_mes; });
                        if (i < 0) {
                            $scope.data.push({
                                ano: d.dtVencimento_ano,
                                mes: d.dtVencimento_mes,
                                mesAno: d.dtVencimento_dmy.substr(3),
                                valor: d.valor,
                                lancamentos: [d]
                            })
                        } else {
                            $scope.data[i].lancamentos.push(d);
                            $scope.data[i].valor += d.valor;
                        }
                    })

            }

            appAuthHelper.ready()
                .then(_ => {
                    $scope.user = appAuthHelper.profile.user;
                    console.info($scope.user);

                    init();
                })

        })

    .directive('lancamentosContrato', function () {
        return {
            restrict: 'E',
            templateUrl: 'lancamentos-contrato/lancamentos-contrato.html',
            controller: 'lancamentosContratoController',
            scope: {
                contrato: "=",
            },
            link: function (scope) {
                scope.$on('$destroy', function () {
                    scope.destroy();
                });
            }
        };
    });

export default ngModule;
