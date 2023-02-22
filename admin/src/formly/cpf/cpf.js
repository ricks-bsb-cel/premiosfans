const ngModule = angular.module('admin.formly.cpf', [])

    .run(function (
        formlyConfig
    ) {

        const fieldObj = {
            name: 'cpf',
            extends: 'input',
            templateUrl: 'cpf/cpf.html',
            controller: function ($scope, $timeout, globalFactory, appConfig) {

                $scope.id = $scope.options.id + "_cpf_" + globalFactory.generateRandomId(7);
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

                $scope.init = _ => {
                    $timeout(function () {
                        var e = document.getElementById($scope.id);
                        VMasker(e).maskPattern(appConfig.get("/masks/cpf"));
                    })
                }
            },
            link: function (scope) {
                scope.init();
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
