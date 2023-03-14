const ngModule = angular.module('formly.integer', [])

    .run(function (
        formlyConfig
    ) {

        const fieldObj = {
            name: 'integer',
            extends: 'input',
            templateUrl: 'integer/integer.html',
            controller: function ($scope, $timeout) {
                $scope.id = $scope.options.id + "_integer";
                $scope.model[$scope.options.key] = parseInt($scope.model[$scope.options.key] || 0);

                $timeout(function () {
                    var e = document.getElementById($scope.id);
                    VMasker(e).maskNumber();
                })

                $scope.newValue = function () {
                    $scope.model[$scope.options.key] = parseInt($scope.model[$scope.options.key] || 0);
                }

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
