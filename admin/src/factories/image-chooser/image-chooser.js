'use strict';

let ngModule;

// https://angular-ui.github.io/bootstrap/

(function () {

    ngModule = angular.module('factories.image-chooser', [])

        .controller('imageChooserModalController',
            function (
                cloudinaryConfig,
                $uibModalInstance,
                blockUiFactory,
                topProgressBarFactory,
                $timeout,
                alertFactory,
                parms
            ) {

                var $ctrl = this;
                var slim = null;

                $ctrl.parms = parms || {};
                $ctrl.imageSrc = null;

                $ctrl.parms.slimOptions = $ctrl.parms.slimOptions || {};
                if (!$ctrl.parms.slimOptions.uploadPreset) { $ctrl.parms.slimOptions.uploadPreset = cloudinaryConfig.defaultUploadPreset };

                $ctrl.searchPexelsDelegate = {
                    selected: function (img) {

                        blockUiFactory.start();

                        // Não use o original para não ESTOURAR toda a base do Cloudinary...
                        var img = img.src.original + '?auto=compress&cs=tinysrgb&fit=crop&h=960&w=1440';

                        slim.load(img, function (e, data) {

                            if (e) {
                                alertFactory.error('Erro fazendo upload da foto...');
                                return;
                            }

                            blockUiFactory.stop();

                        });

                    }
                }
 
                $ctrl.cancel = function () {
                    $uibModalInstance.dismiss();
                };

                $ctrl.upload = function () {
                    var el = $(document.getElementById('image-chooser-modal-slim')).find('.slim-file-hopper');
                    el.trigger('click');
                }

                var uploadFinished = function (data) {
                    delete data.access_mode;
                    delete data.placeholder;
                    delete data.tags;
                    delete data.type;

                    $uibModalInstance.close(data);
                }

                var initSlim = function () {
                    var didConfirm = false;

                    if ($ctrl.parms.slimOptions.ratio == '0:0') { $ctrl.parms.slimOptions.ratio = null };
                    if ($ctrl.parms.slimOptions.size == '0,0') { $ctrl.parms.slimOptions.size = null };
                    if ($ctrl.parms.slimOptions.minSize == '0,0') { $ctrl.parms.slimOptions.minSize = null };

                    var slimOptions = {
                        instantEdit: true,
                        edit: true,
                        size: '512,512',
                        ratio: "1:1",
                        minSize: '512,512',
                        push: true,
                        label: '',
                        statusUploadSuccess: '',
                        labelLoading: "...",
                        serviceFormat: "file",
                        buttonCancelLabel: "Cancelar",
                        buttonCancelTitle: "Cancelar",
                        buttonConfirmLabel: "Salvar",
                        buttonConfirmTitle: "Salvar",
                        didInit: function (blob, canvasElement) {
                            console.info('slim', 'didInit');
                        },
                        didLoad: function (blob, canvasElement, obj, img) {
                            didConfirm = false;
                            console.info('slim', 'didLoad');
                            return true;
                        },
                        didConfirm: function (blob, canvasElement) {
                            didConfirm = true;
                            blockUiFactory.start();
                            topProgressBarFactory.show();

                            console.info('slim', 'didConfirm');
                        },
                        didCancel: function () {
                            console.info('slim', 'didCancel');
                            blockUiFactory.stop();
                        },
                        service: function (blobFile, progress, success, failure) {

                            if (!didConfirm) { return; }

                            var url = cloudinaryConfig.url;
                            var xhr = new XMLHttpRequest();
                            var fd = new FormData();

                            xhr.open('POST', url, true);
                            xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

                            xhr.upload.addEventListener("progress", function (e) {
                                var progress = Math.round((e.loaded * 100.0) / e.total);
                                topProgressBarFactory.set(progress);
                            });

                            xhr.onreadystatechange = function (e) {
                                console.info('onreadystatechange', e);
                                if (xhr.readyState == 4 && xhr.status == 200) {
                                    $timeout(function () {
                                        var response = JSON.parse(xhr.responseText);
                                        blockUiFactory.stop();
                                        topProgressBarFactory.hide();
                                        uploadFinished(response);
                                    })
                                }
                            };

                            fd.append('upload_preset', $ctrl.parms.slimOptions.uploadPreset);
                            fd.append('file', new File(blobFile, blobFile[0].name));

                            xhr.send(fd);

                            success(true);
                        }

                    }

                    slimOptions = angular.merge(slimOptions, $ctrl.parms.slimOptions || {});

                    if (!slimOptions.size) { delete slimOptions.size; }
                    if (!slimOptions.ratio) { delete slimOptions.ratio; }
                    if (!slimOptions.minSize) { delete slimOptions.minSize; }

                    var slimElement = document.getElementById('image-chooser-modal-slim');
                    slim = new Slim(slimElement, slimOptions);
                }

                $timeout(function () {
                    initSlim();
                })

            })

        .factory('imageChooserFactory',

            function (
                $q,
                $uibModal
            ) {

                var showModal = function (parms) {
                    return $q(function (resolve, reject) {
                        var modal = $uibModal.open({
                            windowClass: 'image-chooser-modal',
                            templateUrl: 'image-chooser/image-chooser.html',
                            controller: 'imageChooserModalController',
                            controllerAs: '$ctrl',
                            backdrop: false,
                            size: 'lg',
                            resolve: {
                                parms: function () {
                                    return parms;
                                }
                            }
                        });

                        modal.result.then(function (value) {
                            resolve(value);
                        }, function () {
                            console.info('rejected!');
                            reject();
                        });

                    })
                }

                var show = function (parms) {
                    return $q(function (resolve, reject) {
                        showModal(parms).then(function (e) {
                            resolve(e);
                        }).catch(function () {
                            reject();
                        })
                    })
                }

                var factory = {
                    show: show
                };

                return factory;
            }
        );

})();

export default ngModule;
