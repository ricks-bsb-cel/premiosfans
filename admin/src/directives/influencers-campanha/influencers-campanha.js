'use strict';

let ngModule = angular.module('directives.influencers-campanha', [])

    .controller('influencersCampanhaController',
        function (
            $scope,
            appAuthHelper,
            collectionEmpresas,
            $timeout
        ) {

            $scope.empresas = collectionEmpresas;
            $scope.influencers = $scope.influencers || [];

            $scope.selectAll = _ => {
                $timeout(_ => {
                    if ($scope.isAllSelected()) {
                        $scope.influencers = [];
                    } else {
                        collectionEmpresas.collection.data.forEach(e => {
                            if ($scope.influencers.findIndex(i => { return i.idInfluencer === e.id; }) < 0) {
                                $scope.influencers.push({ idInfluencer: e.id })
                            }
                        });
                    }
                })
            }

            $scope.isAllSelected = _ => {
                return $scope.influencers.length === collectionEmpresas.collection.data.length;
            }

            $scope.isSelected = idInfluencer => {
                return $scope.influencers.findIndex(f => {
                    return f.idInfluencer === idInfluencer;
                }) >= 0;
            }

            $scope.select = idInfluencer => {
                $timeout(_ => {
                    const i = $scope.influencers.findIndex(f => {
                        return f.idInfluencer === idInfluencer;
                    });

                    if (i < 0) {
                        $scope.influencers.push({ idInfluencer: idInfluencer })
                    } else {
                        $scope.influencers = $scope.influencers.filter(f => {
                            return f.idInfluencer !== idInfluencer;
                        })
                    }
                })
            }

            const init = _ => {
                appAuthHelper.ready()
                    .then(_ => {
                        collectionEmpresas.collection.startSnapshot();
                    })
            }

            init();

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
