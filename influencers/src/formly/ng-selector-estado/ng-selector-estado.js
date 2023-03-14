const ngModule = angular.module('formly.ng-selector-estado', [])

    .run(function (
        formlyConfig
    ) {
        var fieldObj = {
            name: 'ng-selector-estado',
            extends: 'input',
            templateUrl: 'ng-selector-estado/ng-selector-estado.html',
            controller: function ($scope) {
                $scope.selectOptions = [
                    { label: "Acre", id: "AC" },
                    { label: "Alagoas", id: "AL" },
                    { label: "Amapá", id: "AP" },
                    { label: "Amazonas", id: "AM" },
                    { label: "Bahia", id: "BA" },
                    { label: "Ceará", id: "CE" },
                    { label: "Espírito Santo", id: "ES" },
                    { label: "Goiás", id: "GO" },
                    { label: "Maranhão", id: "MA" },
                    { label: "Mato Grosso", id: "MT" },
                    { label: "Mato Grosso do Sul", id: "MS" },
                    { label: "Minas Gerais", id: "MG" },
                    { label: "Pará", id: "PA" },
                    { label: "Paraíba", id: "PB" },
                    { label: "Paraná", id: "PR" },
                    { label: "Pernambuco", id: "PE" },
                    { label: "Piauí", id: "PI" },
                    { label: "Rio de Janeiro", id: "RJ" },
                    { label: "Rio Grande do Norte", id: "RN" },
                    { label: "Rio Grande do Sul", id: "RS" },
                    { label: "Rondônia", id: "RO" },
                    { label: "Roraima", id: "RR" },
                    { label: "Santa Catarina", id: "SC" },
                    { label: "São Paulo", id: "SP" },
                    { label: "Sergipe", id: "SE" },
                    { label: "Tocantins", id: "TO" },
                    { label: "Distrito Federal", id: "DF" }
                ]
            }
        };
        formlyConfig.setType(fieldObj);
    });

export default ngModule;
