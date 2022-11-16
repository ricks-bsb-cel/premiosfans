'use strict';

let ngModule = angular.module('directives.sorteio-campanha-premios', [])

    .controller('sorteioCampanhaPremiosController',
        function (
            $scope,
            globalFactory,
            alertFactory
        ) {

            $scope.add = _ => {
                if ($scope.sorteio.premios.length >= 5) {
                    alertFactory.error('Cada sorteio pode ter no máximo 5 prêmios');
                    return;
                }
                $scope.sorteio.premios.push({
                    guidPremio: globalFactory.guid(),
                    valor: 0
                })
            }

            $scope.removerPremio = p => {
                alertFactory.yesno('Tem certeza que deseja remover o prêmio?').then(_ => {
                    $scope.sorteio.premios = $scope.sorteio.premios.filter(f => {
                        return f.guidPremio !== p.guidPremio;
                    })
                })
            }

            $scope.up = pos => {
                if (pos === 0) return;

                const [p] = $scope.sorteio.premios.splice(pos, 1);
                $scope.sorteio.premios.splice(pos - 1, 0, p);
            }

            $scope.clonePremio = pos => {
                let p = $scope.sorteio.premios[pos];

                p = { ...p };

                p.guidPremio = globalFactory.guid();

                delete p.$$hashKey;

                p.id = 'new';

                $scope.sorteio.premios.splice(pos, 0, p);
            }

            $scope.down = pos => {
                if (pos === ($scope.sorteio.premios.length - 1)) return;

                const [p] = $scope.sorteio.premios.splice(pos, 1);
                $scope.sorteio.premios.splice(pos + 1, 0, p);
            }

            const init = _ => {
                $scope.sorteio = $scope.sorteio || {
                    guidSorteio: globalFactory.guid(),
                    dtSorteio: null,
                    ativo: false,
                    premios: []
                };

                $scope.sorteio.premios = $scope.sorteio.premios || [];

                if (!$scope.sorteio.premios.length) $scope.add();
            }

            $scope.clonarSorteio = sorteio => {
                $scope.delegate.clonarSorteio(sorteio);
            }

            $scope.removerSorteio = sorteio => {
                alertFactory.yesno('Tem certeza que deseja remover o Sorteio e TODOS os seus prêmios?').then(_ => {
                    $scope.delegate.removerSorteio(sorteio);
                })
            }

            $scope.situacao = _ => {
                $scope.sorteio.ativo = !$scope.sorteio.ativo;
            }

            init();

        })

    .directive('sorteioCampanhaPremios', function () {
        return {
            restrict: 'E',
            templateUrl: 'sorteio-campanha-premios/sorteio-campanha-premios.html',
            controller: 'sorteioCampanhaPremiosController',
            scope: {
                sorteio: "=",
                delegate: "=",
                posicao: "@"
            }
        };
    });

export default ngModule;
