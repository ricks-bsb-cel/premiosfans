const ngModule = angular.module('admin.formly.ng-selector-tipo-chave-pix', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-tipo-chave-pix',
            extends: 'input',
            templateUrl: 'ng-selector-tipo-chave-pix/ng-selector-tipo-chave-pix.html',
            controller: function ($scope) {
                $scope.selectOptions = [
                    { label: "Aleatória", id: "aleatorio" },
                    { label: "CPF", id: "cpf" },
                    { label: "CNPJ", id: "cnpj" },
                    { label: "eMail", id: "email" },
                    { label: "Celular", id: "celular" },
                ]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
