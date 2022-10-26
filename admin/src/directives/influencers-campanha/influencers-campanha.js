'use strict';

let ngModule = angular.module('directives.influencers-campanha', [])

    .controller('influencersCampanhaController',
        function (
            $scope,
            appAuthHelper
        ) {

            appAuthHelper.ready()
                .then(_ => {
                    $scope.influencers = $scope.influencers || [];

                    appAuthHelper.profile.user.empresas.forEach(e => {
                        let i = $scope.influencers.findIndex(f => {
                            return f.idInfluencer === e.id;
                        });

                        if (i < 0) {
                            $scope.influencers.push({
                                idInfluencer: e.id,
                                selected: false,
                                nome: e.nome
                            })
                        } else {
                            $scope.influencers[i] = {
                                ...$scope.influencers[i],
                                selected: true,
                                nome: e.nome
                            }
                        }
                    })
                })

        })

    .directive('influencersCampanha', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha/influencers-campanha.html',
            controller: 'influencersCampanhaController',
            scope: {
                influencers: "="
            }
        };
    });

export default ngModule;
