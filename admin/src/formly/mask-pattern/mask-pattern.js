const ngModule = angular.module('admin.formly.mask-pattern', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'mask-pattern',
            extends: 'input',
            templateUrl: 'mask-pattern/mask-pattern.html',
            controller: function ($scope, $timeout) {
                $scope.width = $scope.options.templateOptions.width || 140;
                var id = $scope.options.id + "_mask_pattern";
                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskPattern($scope.options.templateOptions.mask || '999999');
                }, 500)
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
