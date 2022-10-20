const ngModule = angular.module('admin.formly.ng-selector-empresa', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-empresa',
            extends: 'input',
            templateUrl: 'ng-selector-empresa/ng-selector-empresa.html',
            controller: function ($scope, appAuthHelper) {

                $scope.ready = false;
                $scope.data = [];

                appAuthHelper.ready().then(_ => {
                    $scope.data = appAuthHelper.profile.user.empresas;
                    $scope.ready = true;
                })

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
