
const ngModule = angular.module('admin.formly.image-upload', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'image-upload',
            extends: 'input',
            templateUrl: 'image-upload/image-upload.html',
            controller: function ($scope, $timeout, formlyFactory) {

                var slimId = $scope.options.key + "_slim";

                var initSlimCloudinary = function () {
                    
                    $scope.options.templateOptions.slim = formlyFactory.slimCloudinary(
                        {
                            elementId: slimId,
                            uploadPreset: $scope.options.templateOptions.uploadPreset || 'ycardapp',
                            options: $scope.options.templateOptions.slimOptions || {},
                            uploadedCallback: function (imageUrl) {
                                $scope.model[$scope.options.key] = imageUrl;
                                console.info($scope.options.key, imageUrl);
                            },
                            cancelCallback: function (imageUrl) {
                                $scope.model[$scope.options.key] = imageUrl;
                                console.info($scope.options.key, imageUrl);
                            },
                            initCallback: function () {
                            }
                        }
                    );

                }

                var startSlimWhenReady = function () {
                    $timeout(function () {
                        if (!$("#" + slimId).length) {
                            startSlimWhenReady();
                        } else {
                            initSlimCloudinary();
                        }
                    }, 500)
                }

                startSlimWhenReady();

            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
