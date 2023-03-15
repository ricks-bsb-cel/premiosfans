'use strict';

import addWidget from "./directives/add/add";

let ngModule = angular.module('directives.influencers-campanha-list', [
    addWidget.name
])

    .controller('influencersCampanhaListController',
        function (
            $scope,
            appAuthHelper,
            collectionEmpresas,
            influencersCampanhaListAddFactory
        ) {
            $scope.list = [];

            appAuthHelper.ready().then(_ => {
                collectionEmpresas.collection.startSnapshot({
                    dataReady: function (empresas) {
                        $scope.list = $scope.campanha.influencers.map(influencer => {
                            const pos = empresas.findIndex(f => f.id === influencer.idInfluencer);

                            return { ...influencer, ...empresas[pos] || {} };
                        })
                    }
                });
            })

            $scope.add = _ => {
                influencersCampanhaListAddFactory.add($scope.campanha);
            }

        })

    .directive('influencersCampanhaList', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha-list/influencers-campanha-list.html',
            controller: 'influencersCampanhaListController',
            scope: {
                campanha: "="
            }
        };
    });

export default ngModule;
