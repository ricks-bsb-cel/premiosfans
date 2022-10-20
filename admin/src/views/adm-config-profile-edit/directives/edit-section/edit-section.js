'use strict';

let ngModule = angular.module('view.adm-config-profile-edit.edit-section', [])

    .controller('admConfigProfilesEditSectionController',

        function (
            $uibModalInstance,
            secao
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;

            $ctrl.data = secao;

            $ctrl.fields = [
                {
                    key: 'titulo',
                    templateOptions: {
                        label: 'Título da seção',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'icon',
                    templateOptions: {
                        required: true,
                        label: 'Ícone'
                    },
                    type: 'fa-icon',
                    className: 'col-12'
                }

            ];

            $ctrl.ok = function () {
                if ($ctrl.form.$valid) {
                    $uibModalInstance.close($ctrl.data);
                }
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('admConfigProfilesEditSectionFactory',

        function (
            $q,
            $uibModal,
            globalFactory
        ) {

            const showModal = function (secao) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'edit-section-modal',
                        templateUrl: 'adm-config-profile-edit/directives/edit-section/edit-section.html',
                        controller: 'admConfigProfilesEditSectionController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        resolve: {
                            secao: function () {
                                return secao;
                            }
                        }
                    });

                    modal.result.then(function (data) {
                        resolve(data);
                    }, function () {
                        reject();
                    });

                })
            }

            const edit = function (secao) {

                var toEdit = angular.copy(secao || {
                    id: globalFactory.guid(),
                    titulo: 'Default',
                    icon: 'fa fa-archive',
                    options: []
                });

                return $q(function (resolve, reject) {
                    showModal(toEdit).then(function (secao) {
                        resolve(secao);
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
