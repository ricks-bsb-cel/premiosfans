'use strict';

let ngModule;

ngModule = angular.module('view.faq.edit', [])

    .controller('faqEditController',
        function (
            $uibModalInstance,
            collectionFaq,
            alertFactory,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            $ctrl.fields = [
                {
                    key: 'pergunta',
                    templateOptions: {
                        label: 'Pergunta',
                        type: 'text',
                        required: true,
                        minlength: 3
                    },
                    type: 'input',
                    className: 'col-12'
                },
                {
                    key: 'resposta',
                    templateOptions: {
                        label: 'Resposta',
                        type: 'text',
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

                collectionFaq.save($ctrl.data).then(function () {
                    $uibModalInstance.close($ctrl.data);
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('faqEditFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'faq-edit-modal',
                        templateUrl: 'faq/directives/edit/edit.html',
                        controller: 'faqEditController',
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

            return {
                edit: edit
            };;
        }
    );

export default ngModule;
