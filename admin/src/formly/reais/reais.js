const ngModule = angular.module('admin.formly.reais', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'reais',
            extends: 'input',
            templateUrl: 'reais/reais.html',
            controller: function ($scope, $timeout) {
                let watchValue = null;

                $scope.value = "0,00";

                const startWatchValue = _ => {
                    watchValue = $scope.$watch('value', function (nv, ov) {
                        if ((nv || nv == 0) && nv != ov) {
                            $scope.model[$scope.options.key] = nv;
                        }
                    });
                }

                const stopWatchValue = _ => {
                    if (watchValue) watchValue();
                }

                $timeout(_ => {
                    $scope.value = $scope.model[$scope.options.key] || 0;
                    startWatchValue();
                })

                $scope.$watch('model', newValue => {
                    const v = newValue && newValue[$scope.options.key] ? newValue[$scope.options.key] : null;
                    if (v) {
                        stopWatchValue();
                        $scope.value = v;
                        startWatchValue();
                    }
                }, true)

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
