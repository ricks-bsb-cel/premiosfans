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

            const setInfluencerOnModel = (idInfluencer, selected) => {
                const pos = $scope.influencers.findIndex(f => { return f.idInfluencer === idInfluencer; });

                if (pos >= 0) {
                    $scope.influencers[pos].selected = selected;
                } else {
                    $scope.influencers.push({
                        idInfluencer: idInfluencer,
                        selected: selected
                    })
                }

            }

            $scope.selectAll = _ => {
                $timeout(_ => {
                    if ($scope.isAllSelected()) {
                        collectionEmpresas.collection.data.forEach(e => {
                            setInfluencerOnModel(e.id, false);
                        });
                    } else {
                        collectionEmpresas.collection.data.forEach(e => {
                            setInfluencerOnModel(e.id, true);
                        });
                    }
                })
            }

            $scope.isAllSelected = _ => {
                return ($scope.influencers || []).filter(f => { return f.selected; }).length === collectionEmpresas.collection.data.length;
            }

            $scope.isSelected = idInfluencer => {
                const pos = ($scope.influencers || []).findIndex(f => { return f.idInfluencer === idInfluencer; });

                return pos >= 0 ? $scope.influencers[pos].selected : false;
            }

            $scope.select = idInfluencer => {
                $timeout(_ => {
                    if ($scope.isSelected(idInfluencer)) {
                        setInfluencerOnModel(idInfluencer, false);
                    } else {
                        setInfluencerOnModel(idInfluencer, true);
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
