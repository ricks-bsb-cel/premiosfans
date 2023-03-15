'use strict';

let ngModule = angular.module('view.influencersCampanhaList.add', [])

    .controller('influencersCampanhaListAddController',
        function (
            $uibModalInstance,
            collectionEmpresas,
            premiosFansService,
            campanha
        ) {

            var $ctrl = this;

            $ctrl.ready = false;
            $ctrl.error = false;

            $ctrl.list = [];

            collectionEmpresas.collection.startSnapshot({
                dataReady: function (empresas) {
                    $ctrl.list = empresas.filter(emp => !campanha.influencers.some(d => d.idInfluencer === emp.id));

                    $ctrl.ready = true;
                }
            });

            $ctrl.ok = function () {

                $ctrl.list.filter(f => f.selected).forEach(l => {
                    premiosFansService.addInfluencerToCampanha({
                        data: {
                            idCampanha: campanha.id,
                            idInfluencer: l.id
                        }
                    })
                });

                $uibModalInstance.close($ctrl.list.filter(f => f.selected));
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('influencersCampanhaListAddFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (campanha) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'influencers-campanha-list-add-modal',
                        templateUrl: 'influencers-campanha-list/directives/add/add.html',
                        controller: 'influencersCampanhaListAddController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
                        resolve: {
                            campanha: function () { return campanha; },
                        }
                    });

                    modal.result.then(function (data) {
                        resolve(data);
                    }, function () {
                        reject();
                    });

                })
            }

            const add = function (campanha) {
                return $q(function (resolve, reject) {
                    showModal(campanha).then(function (data) {
                        resolve(data);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            return {
                add: add
            };
        }
    );

export default ngModule;
