const ngModule = angular.module('admin.formly.reais', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'reais',
            extends: 'input',
            templateUrl: 'reais/reais.html',
            controller: function ($scope, $timeout) {
                $scope.value = "0,00";
                $timeout(function () {
                    $scope.value = $scope.model[$scope.options.key] || 0;
                    $scope.$watch('value', function (nv, ov) {
                        if ((nv || nv == 0) && nv != ov) {
                            $scope.model[$scope.options.key] = nv;
                        }
                    })
                })
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
