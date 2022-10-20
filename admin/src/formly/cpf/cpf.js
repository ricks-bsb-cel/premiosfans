const ngModule = angular.module('admin.formly.cpf', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'cpf',
            extends: 'input',
            templateUrl: 'cpf/cpf.html',
            controller: function ($scope, $timeout, globalFactory, appConfig) {

                var id = $scope.options.id + "_cpf";

                $scope.value = $scope.model[$scope.options.key + '_formatted'] || $scope.model[$scope.options.key] || null;
                $scope.isValid = true;
                $scope.isEmpty = true;

                $scope.$watch('value', function (newvalue, oldvalue) {

                    $scope.isValid = globalFactory.isCPFValido(newvalue);
                    $scope.isEmpty = globalFactory.onlyNumbers(newvalue) === '';

                    if (globalFactory.isCPFValido(newvalue)) {
                        $scope.form.$setValidity($scope.options.key, true);

                        $scope.model[$scope.options.key] = globalFactory.onlyNumbers(newvalue);
                        $scope.model[$scope.options.key + '_formatted'] = newvalue;
                    } else {
                        $scope.form.$setValidity($scope.options.key, false);
                    }
                });

                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskPattern(appConfig.get("/masks/cpf"));
                })
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
