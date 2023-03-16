'use strict';

let ngModule = angular.module('view.influencersCampanhaList.edit', [])

    .controller('influencersCampanhaListEditController',
        function (
            $uibModalInstance,
            collectionCampanhasInfluencers,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'titulo',
                    templateOptions: {
                        label: 'Título',
                        type: 'text',
                        required: true,
                        minlength: 3
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'descricao',
                    templateOptions: {
                        label: 'Descrição',
                        type: 'text',
                        height: 360
                    },
                    type: 'textarea',
                    className: 'col-12'
                },
                {
                    key: 'link',
                    templateOptions: {
                        label: 'Link',
                        type: 'text',
                        height: 360
                    },
                    type: 'input',
                    className: 'col-12'
                }
            ];

            $ctrl.ok = function () {
                $uibModalInstance.close($null);
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('influencersCampanhaListEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (data) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'influencers-campanha-list-edit-modal',
                        templateUrl: 'influencers-campanha-list/directives/edit/edit.html',
                        controller: 'influencersCampanhaListEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
                        resolve: {
                            data: function () { return data; },
                        }
                    });

                    modal.result.then(function (data) {
                        resolve(data);
                    }, function () {
                        reject();
                    });

                })
            }

            const edit = function (data) {
                return $q(function (resolve, reject) {
                    showModal(data).then(function (data) {
                        resolve(data);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            return {
                edit: edit
            };
        }
    );

export default ngModule;
