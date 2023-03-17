'use strict';

/*
One pill makes you larger
And one pill makes you small,
And the ones that mother gives you
Don't do anything at all.
*/

let ngModule;

ngModule = angular.module('view.htmlBlock.edit', [])

    .controller('htmlBlockEditController',
        function (
            $uibModalInstance,
            collectionHtmlBlock,
            alertFactory,
            data
        ) {

            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'sigla',
                    templateOptions: {
                        label: 'Sigla',
                        type: 'text',
                        required: true,
                        minlength: 3
                    },
                    type: 'input',
                    className: 'col-12 monospace'
                },
                {
                    key: 'html',
                    templateOptions: {
                        label: 'HTML',
                        type: 'text',
                        required: true,
                        height: 360
                    },
                    type: 'html-editor',
                    className: 'col-12'
                }
            ];

            $ctrl.ok = function () {
                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionHtmlBlock.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('htmlBlockEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'html-block-edit-modal',
                        templateUrl: 'html-block/directives/edit/edit.html',
                        controller: 'htmlBlockEditController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return e;
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

            var edit = function (original) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit).then(function (updated) {
                        original = updated;
                        resolve(original);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            var factory = {
                edit: edit
            };

            return factory;
        }
    );

export default ngModule;
