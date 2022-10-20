const ngModule = angular.module('admin.formly.ng-selector-tipo-cobranca', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-tipo-cobranca',
            extends: 'input',
            templateUrl: 'ng-selector-tipo-cobranca/ng-selector-tipo-cobranca.html',
            controller: function ($scope) {

                $scope.selectOptions = [
                    { label: "Assinatura Recorrente", id: "ar" },
                    { label: "Parcelado", id: "pa" }
                ]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
