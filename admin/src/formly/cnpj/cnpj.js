const ngModule = angular.module('admin.formly.cnpj', [])

    .run(function (
        formlyConfig
    ) {


        var fieldObj = {
            name: 'cnpj',
            extends: 'input',
            templateUrl: 'cnpj/cnpj.html',
            controller: function ($scope, $timeout, globalFactory) {

                var id = $scope.options.id + "_cnpj";

                $scope.globalFactory = globalFactory;
                $scope.value = $scope.model[$scope.options.key + '_formatted'] || null;

                if (!$scope.value && $scope.model[$scope.options.key]) {
                    $scope.value = globalFactory.formatCnpj($scope.model[$scope.options.key]);
                }

                if (!$scope.value) {
                    const unWatch = $scope.$watch('model', (newValue, oldValue) => {
                        if (newValue[$scope.options.key]) {
                            $scope.value = globalFactory.formatCnpj(newValue[$scope.options.key]);
                            unWatch();
                        }
                    }, true);
                }

                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskPattern('99.999.999/9999-99');
                })

            },
            defaultOptions: {
                validators: {
                    isValidCnpj: {
                        expression: function (newValue, oldValue, scope) {

                            if (scope.globalFactory.isCNPJValido(newValue)) {
                                scope.model[scope.options.key] = scope.globalFactory.onlyNumbers(newValue);
                                scope.model[scope.options.key + '_formatted'] = newValue;

                                return true;
                            } else {
                                scope.model[scope.options.key] = null;
                                scope.model[scope.options.key + '_formatted'] = null;

                                return false;
                            }

                        },
                        message: function () {
                            return 'CNPJ inválido';
                        }
                    }
                }
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
