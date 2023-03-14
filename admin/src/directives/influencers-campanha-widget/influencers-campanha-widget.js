'use strict';

let ngModule = angular.module('directives.influencers-campanha-widget', [])

    .controller('influencersCampanhaWidgetController',
        function (
            $scope,
            appAuthHelper,
            collectionEmpresas
        ) {

            $scope.list = [];

            appAuthHelper.ready()
                .then(_ => {
                    collectionEmpresas.collection.startSnapshot({
                        dataReady: function (empresas) {
                            $scope.list = $scope.influencers.map(influencer => {
                                const pos = empresas.findIndex(f => f.id === influencer.idInfluencer);

                                return { ...influencer, ...empresas[pos] || {} };
                            })
                        }
                    });
                })


        })

    .directive('influencersCampanhaWidget', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha-widget/influencers-campanha-widget.html',
            controller: 'influencersCampanhaWidgetController',
            scope: {
                influencers: "="
            }
        };
    });

export default ngModule;
