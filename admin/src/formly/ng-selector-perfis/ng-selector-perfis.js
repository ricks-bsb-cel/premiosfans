const ngModule = angular.module('admin.formly.ng-selector-perfis', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-perfis',
            extends: 'input',
            templateUrl: 'ng-selector-perfis/ng-selector-perfis.html',
            controller: function ($scope, collectionAdmConfigProfiles) {
                $scope.admConfigProfiles = collectionAdmConfigProfiles;
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
