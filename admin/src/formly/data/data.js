const ngModule = angular.module('admin.formly.data', [])

    .run(function (
        formlyConfig
    ) {

        formlyConfig.setType({
            name: 'data',
            extends: 'input',
            templateUrl: 'data/data.html',
            controller: function ($scope, $timeout, appFirestoreHelper, appConfig) {

                $scope.value = $scope.model[$scope.options.key + '_ddmmyyyy'] || null;
                $scope.id = $scope.options.id + "data";

                $scope.$watch('value', function (newValue, oldValue) {
                    if (newValue && newValue.length == 10) {
                        
                        var d = moment(newValue, 'DD/MM/YYYY');

                        if (d.isValid()) {
                            $scope.model[$scope.options.key] = d.format('YYYY-MM-DD');
                            $scope.model[$scope.options.key + '_ddmmyyyy'] = d.format('DD/MM/YYYY');
                            $scope.model[$scope.options.key + '_timestamp'] = appFirestoreHelper.toTimestamp(d.toDate());
                            $scope.form.$setValidity($scope.options.key, true)
                        } else {
                            $scope.form.$setValidity($scope.options.key, false);
                        }
                    }
                })

                $timeout(function () {
                    var e = document.getElementById($scope.id);
                    VMasker(e).maskPattern(appConfig.get("/masks/data/VMasker"));
                })

            }
        });

    });

export default ngModule;
