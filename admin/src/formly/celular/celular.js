const ngModule = angular.module('admin.formly.celular', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'celular',
            extends: 'input',
            templateUrl: 'celular/celular.html',
            controller: function ($scope, $timeout, globalFactory, appConfig) {

                var id = $scope.options.id + "_celular";

                $scope.value = $scope.model[$scope.options.key + '_formatted'] || $scope.model[$scope.options.key] || null;

                $scope.$watch('value', function (newvalue) {

                    var noMask = globalFactory.onlyNumbers(newvalue);

                    if (noMask.length === 11) {

                        $scope.form.$setValidity($scope.options.key, true);

                        $scope.model[$scope.options.key + '_formatted'] = VMasker.toPattern(noMask, appConfig.get("/masks/celular"));

                        $scope.model[$scope.options.key] = noMask;
                        $scope.model[$scope.options.key + '_int'] = '55' + noMask;
                        $scope.model[$scope.options.key + '_intplus'] = '+55' + noMask;
                    } else {
                        $scope.form.$setValidity($scope.options.key, false);
                    }

                });

                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskPattern(appConfig.get("/masks/celular"));
                })

            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
