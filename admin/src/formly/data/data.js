const ngModule = angular.module('admin.formly.data', [])

    .run(function (
        formlyConfig
    ) {

        formlyConfig.setType({
            name: 'data',
            extends: 'input',
            templateUrl: 'data/data.html',
            controller: function ($scope, $timeout, appFirestoreHelper, appConfig) {

                let unWatch = null;

                $scope.value = $scope.model[$scope.options.key + '_ddmmyyyy'] || null;
                $scope.id = $scope.options.id + "data";
                
                const startWatch = _ => {
                    unWatch = $scope.$watch('value', function (newValue, oldValue) {
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
                }

                const stopWatch = _ => {
                    if (unWatch) unWatch();
                }

                $scope.$watch('model', function (newValue, oldValue) {
                    if (newValue[$scope.options.key + '_ddmmyyyy'] !== oldValue[$scope.options.key + '_ddmmyyyy']) {
                        stopWatch();
                        $scope.value = newValue[$scope.options.key + '_ddmmyyyy'];
                        startWatch();
                    }
                }, true);

                $timeout(function () {
                    var e = document.getElementById($scope.id);
                    VMasker(e).maskPattern(appConfig.get("/masks/data/VMasker"));
                    startWatch();
                })

            }
        });

    });

export default ngModule;
