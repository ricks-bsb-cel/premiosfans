const ngModule = angular.module('admin.formly.ng-selector-plano', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-plano',
            extends: 'input',
            templateUrl: 'ng-selector-plano/ng-selector-plano.html',
            controller: function ($scope, collectionPlanos) {
                $scope.collectionPlanos = collectionPlanos;

                if (typeof $scope.options.templateOptions.disabled === 'undefined') {
                    $scope.options.templateOptions.disabled = false;
                }
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
