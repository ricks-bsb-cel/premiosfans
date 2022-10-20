const ngModule = angular.module('admin.formly.data-dd', [])

    .run(function (
        formlyConfig
    ) {

        formlyConfig.setType({
            name: 'data-dd',
            extends: 'input',
            templateUrl: 'data-dd/data-dd.html',
            controller: function ($scope, $timeout, toastrFactory) {
                $scope.value = $scope.model[$scope.options.key] || null;
                $scope.id = $scope.options.id + "-data-dd";

                $scope.$watch('model', function (newValue, oldVaue) {
                    if (newValue[$scope.options.key]) {
                        $scope.value = newValue[$scope.options.key];
                    }
                }, true);

                $scope.lastCheck = _ => {
                    if ($scope.model[$scope.options.key] >= 28) {
                        toastrFactory.info(`Vencimentos do dia ${$scope.model[$scope.options.key]} serão antecipados para o último dia do mês caso o data não exista.`);
                    }
                }

                $scope.$watch('value', function (newValue, oldValue) {

                    if (newValue) {

                        var d = parseInt(newValue);

                        if (d >= 1 && d <= 31) {
                            $scope.model[$scope.options.key] = d;

                            $scope.form.$setValidity($scope.options.key, true);
                        } else {
                            $scope.value = null;
                            delete $scope.model[$scope.options.key];

                            $scope.form.$setValidity($scope.options.key, false);
                        }
                    }
                })

                $timeout(function () {
                    var e = document.getElementById($scope.id);
                    VMasker(e).maskPattern("99");
                })

            }
        });

    });

export default ngModule;
