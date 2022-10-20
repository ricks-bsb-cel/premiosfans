const ngModule = angular.module('admin.formly.ng-selector-contas', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-contas',
            extends: 'input',
            templateUrl: 'ng-selector-contas/ng-selector-contas.html',
            controller: function ($scope, collectionContas) {
                $scope.collectionContas = collectionContas;

                if (typeof $scope.options.templateOptions.disabled === 'undefined') {
                    $scope.options.templateOptions.disabled = false;
                }
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
