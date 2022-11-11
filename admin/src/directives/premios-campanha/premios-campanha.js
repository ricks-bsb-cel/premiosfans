'use strict';

let ngModule = angular.module('directives.premios-campanha', [])

    .controller('premiosCampanhaController',
        function (
            $scope,
            globalFactory
        ) {

            $scope.premios = $scope.premios || [
                {
                    guidPremio: globalFactory.guid()
                }
            ];

            $scope.add = _ => {
                $scope.premios.push({
                    guidPremio: globalFactory.guid(),
                    qtd: 1,
                    valor: 0
                })
            }

            $scope.remove = p => {
                $scope.premios = $scope.premios.filter(f => {
                    return f.guidPremio !== p.guidPremio;
                })
            }

            $scope.up = pos => {
                if (pos === 0) return;

                const [p] = $scope.premios.splice(pos, 1);
                $scope.premios.splice(pos - 1, 0, p);
            }

            $scope.clone = pos => {
                let p = $scope.premios[pos];
                p = { ...p };
                p.guidPremio = globalFactory.guid();
                delete p.$$hashKey;

                $scope.premios.splice(pos, 0, p);
            }

            $scope.down = pos => {
                if (pos === ($scope.premios.length - 1)) return;

                const [p] = $scope.premios.splice(pos, 1);
                $scope.premios.splice(pos + 1, 0, p);
            }

        })

    .directive('premiosCampanha', function () {
        return {
            restrict: 'E',
            templateUrl: 'premios-campanha/premios-campanha.html',
            controller: 'premiosCampanhaController',
            scope: {
                premios: "="
            }
        };
    });

export default ngModule;
