const ngModule = angular.module('formly.email', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'email',
            extends: 'input',
            templateUrl: 'email/email.html',
            controller: function ($scope, $timeout, globalFactory) {

                var id = $scope.options.id + "_email";

                $scope.globalFactory = globalFactory;

                if (typeof $scope.to.disabled !== 'function') {
                    $scope.to.disabled = _ => { return false; }
                }

                if (!$scope.value && $scope.model[$scope.options.key]) {
                    $scope.value = $scope.model[$scope.options.key].toLowerCase();
                }

                const unWatch = $scope.$watch('model', (newValue, oldValue) => {
                    $scope.value = (newValue[$scope.options.key] || '').toLowerCase();
                }, true);

                $timeout(function () {
                    var e = document.getElementById(id);
                })

                $scope.$on('$destroy', function () {
                    unWatch();
                });

            },
            defaultOptions: {
                validators: {
                    isValidEmail: {
                        expression: function (newValue, oldValue, scope) {

                            if (newValue && scope.globalFactory.emailIsValid(newValue)) {
                                scope.model[scope.options.key] = newValue.toLowerCase();

                                return true;
                            } else {
                                scope.model[scope.options.key] = null;

                                return false;
                            }

                        },
                        message: function () {
                            return 'eMail inválido';
                        }
                    }
                }
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
