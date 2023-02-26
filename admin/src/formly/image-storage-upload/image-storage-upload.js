
const ngModule = angular.module('admin.formly.image-storage-upload', [])

    .run(function (
        formlyConfig
    ) {

        const getSizes = size => {
            const [width, height] = size.split(':');
            return { width: parseInt(width), height: parseInt(height) };
        }

        const fieldObj = {
            name: 'image-storage-upload',
            extends: 'input',
            templateUrl: 'image-storage-upload/image-storage-upload.html',
            controller: function ($scope, $timeout, globalFactory, alertFactory) {
                const
                    size = '512:512',
                    minSize = '512:512',
                    ratio = '1:1';

                let
                    slimObj = null,
                    slimElement = null;

                $scope.id = `${$scope.options.key}-image-storage-upload-${globalFactory.generateRandomId(7)}`

                $scope.options.templateOptions.slimOptions ??= {};
                $scope.options.templateOptions.screenSize ??= { width: '100px', height: '100px' }

                $scope.options.templateOptions.slimOptions.size ??= size;
                $scope.options.templateOptions.slimOptions.minSize ??= minSize;
                $scope.options.templateOptions.slimOptions.ratio ??= ratio;

                $scope.init = _ => {

                    let slimOptions = {
                        elementId: $scope.id,
                        instantEdit: false,
                        edit: true,
                        size: $scope.options.templateOptions.slimOptions.size,
                        ratio: $scope.options.templateOptions.slimOptions.ratio,
                        minSize: $scope.options.templateOptions.slimOptions.minSize,
                        push: true,
                        label: "",
                        statusUploadSuccess: "",
                        labelLoading: "...",
                        serviceFormat: "file",
                        buttonCancelLabel: "Cancelar",
                        buttonCancelTitle: "Cancelar",
                        buttonConfirmLabel: "Salvar",
                        buttonConfirmTitle: "Salvar",

                        /*
                        didInit: function (obj, element) {
                            console.info('didInit', obj, element);

                            const input = $(`#${$scope.id} input[type=file]`)[0];

                            input.addEventListener('change', () => {
                                if (!input.files || !input.files[0]) return;

                                const file = input.files[0];

                                if (!file.type.match(/^image\//)) {
                                    alertFactory.error('O arquivo não é de imagem');
                                    return false;
                                }

                                const reader = new FileReader();

                                reader.onload = (event) => {
                                    const image = new Image();

                                    image.onload = () => {
                                        const minWidth = getSizes($scope.options.templateOptions.slimOptions.minSize).width,
                                            minHeight = getSizes($scope.options.templateOptions.slimOptions.minSize).height;

                                        if (image.width < minWidth || image.height < minHeight) {
                                            alertFactory.error(`A imagem não tem o tamanho mínimo de ${minWidth}px de largura por ${minHeight}px de altura.`);
                                        }
                                    };

                                    image.src = window.URL.createObjectURL(file);
                                };

                                reader.readAsDataURL(file);

                            })

                        },
                        didConfirm: function (obj, element) {
                            console.info('didConfirm', obj, element);

                            // Abre o image cutter
                            obj.load({
                                service: function (file, callback) {
                                    callback(file);
                                }
                            });
                        },
                        didLoad: function () {
                            return true;
                        },
                        */

                        service: function (blobFile, progress, success, failure) {
                            console.info('service', progress);

                            debugger;
                        }
                    };

                    // Permite a atualização de opções
                    slimOptions = {
                        ...slimOptions,
                        ...$scope.options.templateOptions.slimOptions
                    };

                    $timeout(_ => {
                        slimElement = document.getElementById($scope.id);
                        console.info(slimElement, slimOptions);

                        slimObj = new Slim(slimElement, slimOptions);
                    })
                }

            },
            link: function (scope) {
                scope.init();
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
