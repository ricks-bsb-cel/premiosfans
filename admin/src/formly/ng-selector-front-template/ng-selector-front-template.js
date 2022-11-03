const ngModule = angular.module('admin.formly.ng-selector-front-template', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-front-template',
            extends: 'input',
            templateUrl: 'ng-selector-front-template/ng-selector-front-template.html',
            controller: function ($scope, collectionFrontTemplates) {
                $scope.collectionFrontTemplates = collectionFrontTemplates;
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
