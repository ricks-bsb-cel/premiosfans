
const ngModule = angular.module('admin.formly.custom-checkbox', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'custom-checkbox',
            extends: 'input',
            templateUrl: 'custom-checkbox/custom-checkbox.html',
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
