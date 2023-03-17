'use strict';

let ngModule = angular.module('directives.sorteio-campanha-premios', [])

    .controller('sorteioCampanhaPremiosController',
        function (
            $scope,
            globalFactory,
            alertFactory
        ) {

            $scope.add = _ => {

                $scope.sorteio.premios = $scope.sorteio.premios || [];

                $scope.sorteio.premios.push({
                    guidPremio: globalFactory.guid(),
                    valor: 0,
                    deleted: false
                })
            }

            $scope.removerPremio = p => {
                alertFactory.yesno('Tem certeza que deseja remover o prêmio?').then(_ => {
                    p.deleted = true;
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
                    deleted: false,
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

            $scope.permitirInclusaoPremios = _ => {
                return true; // $scope.sorteio.premios.filter(f => { return !f.deleted; }).length < 5;
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
