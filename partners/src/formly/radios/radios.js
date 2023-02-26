
const ngModule = angular.module('formly.radios', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'radios',
            extends: 'input',
            templateUrl: 'radios/radios.html',
            controller: function ($scope, globalFactory) {

                if (!$scope.options.templateOptions.options) {
                    console.error('Informe templateOptions.options (com id, value, label e msg) no formly de tipo radios!');
                    return false;
                }

                $scope.options.templateOptions.inputName = globalFactory.guid();

                if (typeof $scope.model[$scope.options.key] !== 'undefined') {
                    $scope.localModel = ($scope.model[$scope.options.key] || '').toString();
                }

                $scope.set = function (nv) {
                    $scope.localModel = nv.toString();
                    $scope.model[$scope.options.key] = $scope.localModel;
                }

            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
