'use strict';

let ngModule = angular.module('directives.sorteios-campanha', [])

    .controller('sorteiosCampanhaController',
        function (
            $scope,
            globalFactory
        ) {

            $scope.add = _ => {
                $scope.sorteios.push({
                    ativo: false,
                    dtSorteio: null,
                    guidSorteio: globalFactory.guid()
                })
            }

            const init = _ => {
                $scope.sorteios = $scope.sorteios || [];

                if (!$scope.sorteios.length) $scope.add();
            }

            $scope.delegate = {
                add: function () {
                    $scope.add();
                }
            }

            $scope.delegate = {
                clonarSorteio: sorteio => {

                    const s = {
                        ativo: false,
                        guidSorteio: globalFactory.guid(),
                        dtSorteio: null,
                        id: 'new'
                    };

                    sorteio = {
                        ...sorteio,
                        ...s
                    };

                    sorteio.premios = sorteio.premios.map(p => {
                        return {
                            descricao: p.descricao,
                            guidPremio: globalFactory.guid(),
                            valor: p.valor,
                            id: 'new'
                        };
                    })

                    $scope.sorteios.push(sorteio);
                },
                removerSorteio: sorteio => {
                    $scope.sorteios = $scope.sorteios.filter(f => {
                        return f.guidSorteio !== sorteio.guidSorteio;
                    })
                }
            }

            init();

        })

    .directive('sorteiosCampanha', function () {
        return {
            restrict: 'E',
            templateUrl: 'sorteios-campanha/sorteios-campanha.html',
            controller: 'sorteiosCampanhaController',
            scope: {
                sorteios: "="
            }
        };
    });

export default ngModule;
