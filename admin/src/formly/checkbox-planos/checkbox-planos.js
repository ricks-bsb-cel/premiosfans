const ngModule = angular.module('admin.formly.checkbox-planos', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {
        var fieldObj = {
            name: 'checkbox-planos',
            extends: 'input',
            templateUrl: 'checkbox-planos/checkbox-planos.html',
            controller: function ($scope, collectionPlanos) {

                $scope.collectionPlanos = collectionPlanos;




            }
        };

        formlyConfig.setType(fieldObj);
    });

export default ngModule;
