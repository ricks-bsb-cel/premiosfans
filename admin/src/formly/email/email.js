const ngModule = angular.module('admin.formly.email', [])

    .run(function (
        formlyConfig
    ) {

        var lowerCase = function (value) {
            return (value || '').toLowerCase();
        };

        var fieldObj = {
            name: 'email',
            extends: 'input',
            defaultOptions: {
                templateOptions: {
                    type: 'email',
                    pattern: '^[a-z0-9!$%&\'+/=?^_`{|}~-]+(?:\\.[a-z0-9!$%&\'+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$'
                },
                validation: {
                    messages: {
                        pattern: function () {
                            return inputErrorMessages.emailInvalido;
                        }
                    }
                },
                parsers: [lowerCase],
                formatters: [lowerCase]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
