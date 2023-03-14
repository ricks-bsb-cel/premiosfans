
const ngModule = angular.module('formly.url', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'url',
            extends: 'input',
            templateUrl: 'url/url.html',
            controller: function ($scope) {
                $scope.value = $scope.model[$scope.options.key];
                $scope.$watch('value', function (nv, ov) {
                    if ($scope.model[$scope.options.key] != nv) {
                        $scope.model[$scope.options.key] = nv;
                        if ($scope.options.data.onChanged && typeof $scope.options.data.onChanged == 'function') {
                            $scope.options.data.onChanged({
                                key: $scope.options.key,
                                newValue: nv,
                                oldValue: ov
                            });
                        }
                    }
                })
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
