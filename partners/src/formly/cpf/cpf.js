const ngModule = angular.module('formly.cpf', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'cpf',
            extends: 'input',
            templateUrl: 'cpf/cpf.html',
            controller: function ($scope, $timeout, globalFactory) {

                var id = $scope.options.id + "_cpf";

                $scope.globalFactory = globalFactory;
                $scope.value = $scope.model[$scope.options.key + '_formatted'] || $scope.model[$scope.options.key] || null;

                if (!$scope.value && $scope.model[$scope.options.key]) {
                    $scope.value = globalFactory.formatCpf($scope.model[$scope.options.key]);
                }

                if (!$scope.value) {
                    const unWatch = $scope.$watch('model', (newValue, oldValue) => {
                        if (newValue[$scope.options.key]) {
                            $scope.value = globalFactory.formatCpf(newValue[$scope.options.key]);
                            unWatch();
                        }
                    }, true);
                }

                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskPattern('999.999.999-99');
                })

            },
            defaultOptions: {
                validators: {
                    isValidCnpj: {
                        expression: function (newValue, oldValue, scope) {

                            if (scope.globalFactory.isCPFValido(newValue)) {
                                scope.model[scope.options.key] = scope.globalFactory.onlyNumbers(newValue);
                                scope.model[scope.options.key + '_formatted'] = scope.globalFactory.formatCpf(newValue);

                                return true;
                            } else {
                                scope.model[scope.options.key] = null;
                                scope.model[scope.options.key + '_formatted'] = null;

                                return false;
                            }

                        },
                        /*
                        expression: function (newValue, oldValue, scope) {
                            return scope.isCPFValido(newValue);
                        },
                        */
                        message: function () {
                            return 'CPF inválido';
                        }
                    }
                }
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
