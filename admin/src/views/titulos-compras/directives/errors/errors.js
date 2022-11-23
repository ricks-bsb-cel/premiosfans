'use strict';

const ngModule = angular.module('view.titulos-compras.errors', [])

    .controller('titulosComprasErrorsController',
        function (
            $uibModalInstance,
            data
        ) {

            var $ctrl = this;

            $ctrl.tituloCompra = data;

            $ctrl.close = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('titulosComprasErrorsFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (data) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'titulos-compras-errors-modal',
                        templateUrl: 'titulos-compras/directives/errors/errors.html',
                        controller: 'titulosComprasErrorsController',
                        controllerAs: '$ctrl',
                        size: data.errorsExists ? 'xl' : 'md',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return data;
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

            var show = function (data) {

                return $q(function (resolve, reject) {
                    showModal(data)
                        .then(function () {
                            resolve();
                        }).catch(function () {
                            reject();
                        })
                })
            }

            return {
                show: show
            };
        }
    );

export default ngModule;
