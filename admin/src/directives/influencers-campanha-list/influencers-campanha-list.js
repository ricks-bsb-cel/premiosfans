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
            premiosFansService,
            influencersCampanhaListAddFactory,
            blockUiFactory,
            toastrFactory,
            alertFactory
        ) {
            $scope.empresas = null;
            $scope.list = [];

            let endWatch = null;

            appAuthHelper.ready().then(_ => {
            })

            $scope.add = _ => {
                influencersCampanhaListAddFactory.add($scope.campanha);
            }

            const init = _ => {
                collectionEmpresas.collection.startSnapshot({
                    dataReady: function (data) {
                        $scope.empresas = data;

                        initWatch();
                    }
                });
            }

            const updateList = (e) => {
                $scope.list = $scope.campanha.influencers.map(influencer => {
                    const pos = $scope.empresas.findIndex(f => f.id === influencer.idInfluencer);

                    if (pos >= 0) {
                        influencer.nome = $scope.empresas[pos].nome;
                        influencer.nomeExibicao = $scope.empresas[pos].nomeExibicao;
                        influencer.email = $scope.empresas[pos].email;
                        influencer.celular_formatted = $scope.empresas[pos].celular_formatted;
                        influencer.images = $scope.empresas[pos].images || null;
                    }

                    return influencer;
                })
            }

            const initWatch = _ => {
                if (endWatch) return;
                endWatch = $scope.$watch('campanha.influencers', function () {
                    updateList();
                }, true)
            }

            $scope.showAdd = _ => {
                if (!$scope.empresas) return false;

                return $scope.empresas.length > $scope.list.length;
            }

            const enableDisableInfluencer = (data, nome) => {
                blockUiFactory.start();

                premiosFansService.addInfluencerToCampanha({
                    data: data,
                    success: function () {
                        blockUiFactory.stop();

                        if (data.ativo) {
                            toastrFactory.info(`O influencer ${nome} será ativado na campanha. Aguarde alguns instantes...`);
                        } else {
                            toastrFactory.info(`O influencer ${nome} será desativado na campanha. Aguarde alguns instantes...`);
                        }
                    }
                })

            }

            $scope.enableDisable = influencerCampanha => {
                if (influencerCampanha.ativo) {
                    alertFactory.yesno(`Tem certeza que deseja desativar o influencer ${influencerCampanha.nomeExibicao}?`, 'Desativar Influencer').then(function () {
                        enableDisableInfluencer({ ativo: false, idCampanha: influencerCampanha.idCampanha, idInfluencer: influencerCampanha.idInfluencer }, influencerCampanha.nomeExibicao);
                    });
                } else {
                    enableDisableInfluencer({ ativo: true, idCampanha: influencerCampanha.idCampanha, idInfluencer: influencerCampanha.idInfluencer }, influencerCampanha.nomeExibicao);
                }
            }


            $scope.destroy = _ => {
                if (endWatch) endWatch();
            }

            init();
        })

    .directive('influencersCampanhaList', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha-list/influencers-campanha-list.html',
            controller: 'influencersCampanhaListController',
            scope: {
                campanha: "="
            },
            link: function (scope) {
                scope.$on('$destroy', function () {
                    scope.destroy();
                });
            }
        };
    });

export default ngModule;
