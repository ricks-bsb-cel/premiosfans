const ngModule = angular.module('formly.celular', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'celular',
            extends: 'input',
            templateUrl: 'celular/celular.html',
            controller: function ($scope, $timeout, globalFactory) {

                $scope.globalFactory = globalFactory;
                $scope.international = typeof $scope.options.templateOptions.international !== 'undefined' ? $scope.options.templateOptions.international : false;

                if (typeof $scope.to.disabled !== 'function') {
                    $scope.to.disabled = _ => { return false; }
                }

                const id = $scope.options.id + "_celular";

                const set = value => {

                    if (!value) {
                        $scope.value = null;

                        $scope.model[$scope.options.key] = null;
                        $scope.model[$scope.options.key + '_int'] = null;
                        $scope.model[$scope.options.key + '_intplus'] = null;

                        return null;
                    }

                    let noMask = globalFactory.onlyNumbers(value) || '';

                    if (noMask.length === 11) {
                        $scope.set11Digitos(noMask);
                        $scope.value = $scope.model[$scope.options.key + '_formatted'];
                    } else if (noMask.length === 13) {
                        $scope.set13Digitos(noMask);
                        $scope.value = $scope.model[$scope.options.key + '_formatted'];
                    }
                }

                $scope.set11Digitos = value => {
                    $scope.model[$scope.options.key + '_formatted'] = VMasker.toPattern(value, '(99) 9 9999-9999');

                    $scope.model[$scope.options.key] = value;
                    $scope.model[$scope.options.key + '_int'] = '55' + value;
                    $scope.model[$scope.options.key + '_intplus'] = '+55' + value;

                    return true;
                }

                $scope.set13Digitos = value => {

                    var ddi = value.substr(0, 2);
                    var number = value.substr(2);

                    $scope.model[$scope.options.key + '_formatted'] = VMasker.toPattern(number, '(99) 9 9999-9999');

                    $scope.model[$scope.options.key] = '+' + value;
                    $scope.model[$scope.options.key + '_int'] = value;
                    $scope.model[$scope.options.key + '_intplus'] = '+' + value;

                    return true;
                }

                if ($scope.model[$scope.options.key]) {
                    set($scope.model[$scope.options.key]);
                }

                const unWatch = $scope.$watch('model', (newValue, oldValue) => {
                    set(newValue[$scope.options.key]);
                }, true);

                $timeout(function () {
                    var e = document.getElementById(id);
                    if ($scope.international) {
                        VMasker(e).maskPattern('+99 (99) 9 9999-9999');
                    } else {
                        VMasker(e).maskPattern('(99) 9 9999-9999');
                    }
                })

                $scope.$on('$destroy', function () {
                    unWatch();
                });

            },
            defaultOptions: {
                validators: {
                    isValidCelular: {
                        expression: (newValue, oldValue, scope) => {

                            var noMask = scope.globalFactory.onlyNumbers(newValue) || '';

                            if (noMask.length === 13 && scope.international) {
                                scope.form.$setValidity(scope.options.key, true);
                                return set13Digitos(noMask);
                            } else if (noMask.length === 11) {
                                scope.form.$setValidity(scope.options.key, true);
                                return scope.set11Digitos(noMask);
                            } else {
                                scope.form.$setValidity(scope.options.key, false);
                                return false;
                            }

                        },
                        message: function () {
                            return 'Celular inválido';
                        }
                    }
                }
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
