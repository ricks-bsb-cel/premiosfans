
const ngModule = angular.module('formly.range', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'range',
            extends: 'input',
            templateUrl: 'range/range.html',
            controller: function ($scope) {

                $scope.options.templateOptions.minValue = $scope.options.templateOptions.minValue || 0;
                $scope.options.templateOptions.maxValue = $scope.options.templateOptions.maxValue || 100;
                $scope.options.templateOptions.step = $scope.options.templateOptions.step || 10;

                console.info($scope.options.templateOptions);
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
