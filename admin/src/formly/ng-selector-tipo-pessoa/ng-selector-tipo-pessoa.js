const ngModule = angular.module('admin.formly.ng-selector-tipo-pessoa', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-tipo-pessoa',
            extends: 'input',
            templateUrl: 'ng-selector-tipo-pessoa/ng-selector-tipo-pessoa.html',
            controller: function ($scope) {

                $scope.selectOptions = [
                    { label: "Pessoa Jurídica", id: "pj" },
                    { label: "Pessoa Física", id: "pf" }
                ]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
