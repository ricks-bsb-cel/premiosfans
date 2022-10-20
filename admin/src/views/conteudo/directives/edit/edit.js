'use strict';

import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';

/*
One pill makes you larger
And one pill makes you small,
And the ones that mother gives you
Don't do anything at all.
*/

let ngModule;

ngModule = angular.module('view.conteudo.edit', [])

    .controller('conteudoEditController',
        function (
            $uibModalInstance,
            collectionConteudo,
            alertFactory,
            toastrFactory,
            data,
            $timeout,
            $scope
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
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                    className: 'col-9'
                },
                {
                    key: 'publico',
                    className: 'col-3 publico',
                    defaultValue: false,
                    templateOptions: {
                        title: 'Público',
                    },
                    type: 'custom-checkbox'
                },
                {
                    key: 'descricao',
                    className: 'col-12',
                    templateOptions: {
                        label: 'Descrição',
                        type: 'text',
                        required: true,
                        minlength: 3,
                        maxlength: 64
                    },
                    type: 'input',
                }


            ];

            $ctrl.ok = function (closeModal) {

                closeModal = typeof closeModal === 'boolean' ? closeModal : true;
                $ctrl.data.html = $ctrl.editor.getValue();

                if ($ctrl.form.$invalid) {
                    alertFactory.error('Verifique os dados informados nos campos.', 'Dados inválidos');
                    return;
                }

                collectionConteudo.save($ctrl.data).then(function () {
                    if (closeModal) {
                        $uibModalInstance.close($ctrl.data);
                    } else {
                        toastrFactory.success('Conteúdo salvo com sucesso');
                    }
                });
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };

            const initEditorHtml = function () {

                $ctrl.editor = monaco.editor.create(document.getElementById('monaco-editor-html'), {
                    language: 'html',
                    lineNumbers: 'on',
                    roundedSelection: false,
                    scrollBeyondLastLine: false,
                    readOnly: false,
                    autoIndent: true,
                    formatOnPaste: true,
                    formatOnType: true,
                    theme: 'vs-dark',
                    value: $ctrl.data.html || null
                });

                $ctrl.editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_S, function () {
                    $ctrl.ok(false);
                });

            }

            $timeout(_ => {
                initEditorHtml();
            }, 250)

            $scope.$on('$destroy', function () {
                $ctrl.editor.getModel().dispose();
                $ctrl.editor.dispose();
            });

        })

    .factory('conteudoEditFactory',

        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'conteudo-edit-modal',
                        templateUrl: 'conteudo/directives/edit/edit.html',
                        controller: 'conteudoEditController',
                        controllerAs: '$ctrl',
                        backdrop: false,
                        size: 'lg',
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
