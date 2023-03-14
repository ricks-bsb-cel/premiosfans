
const ngModule = angular.module('formly.image-upload', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'image-upload',
            extends: 'input',
            templateUrl: 'image-upload/image-upload.html',
            controller: function ($scope, $timeout, formlyFactory) {

                var slimId = $scope.options.key + "_slim";

                $scope.showProgress = false;
                $scope.percentProgress = 0;

                $scope.initSlimCloudinary = _ => {
                    $timeout(_ => {
                        initSlimCloudinary();
                    })
                }

                const initSlimCloudinary = _ => {

                    $scope.options.templateOptions.slim = formlyFactory.slimCloudinary(
                        {
                            elementId: slimId,
                            options: $scope.options.templateOptions.slimOptions || {},
                            uploadedCallback: imageUrl => {
                                $timeout(_ => {
                                    $scope.model[$scope.options.key] = imageUrl;
                                })
                            },
                            didRemove: _ => {
                                $timeout(_ => {
                                    $scope.model[$scope.options.key] = null;
                                })
                            },
                            /*
                            cancelCallback: imageUrl => {
                                $scope.model[$scope.options.key] = imageUrl;
                            },
                            */
                            uploadStart: _ => {
                                $timeout(_ => {
                                    $scope.percentProgress = 0;
                                    $scope.showProgress = true;
                                });
                            },
                            uploadEnd: _ => {
                                $timeout(_ => { $scope.showProgress = false; });
                            },
                            uploadProgress: percent => {
                                $timeout(_ => {
                                    $scope.percentProgress = percent;
                                });
                            }
                        }
                    );

                }

            },
            link: function (scope, element, attr) {
                scope.initSlimCloudinary();
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
