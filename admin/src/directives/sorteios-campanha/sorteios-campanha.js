'use strict';

let ngModule = angular.module('directives.sorteios-campanha', [])

    .controller('sorteiosCampanhaController',
        function (
            $scope
        ) {

            $scope.add = _ => {
                $scope.sorteios.push({
                    ativo: false,
                    dtSorteio: null
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
                clonarSorteio: _ => {
                    $scope.add();
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
