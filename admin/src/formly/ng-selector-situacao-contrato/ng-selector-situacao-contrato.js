const ngModule = angular.module('admin.formly.ng-selector-situacao-contrato', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-situacao-contrato',
            extends: 'input',
            templateUrl: 'ng-selector-situacao-contrato/ng-selector-situacao-contrato.html',
            controller: function ($scope) {

                $scope.disabled = $scope.options.ngModelElAttrs && $scope.options.ngModelElAttrs.disabled === 'true';
                $scope.id = $scope.options.id + "-ng-selector-situacao-contrato";

                if (!$scope.model[$scope.options.key]) {
                    $scope.model[$scope.options.key] = 'preparacao';
                }

                $scope.selectOptions = [
                    {
                        id: "preparacao",
                        label: "Em Preparação"
                    },
                    {
                        id: "ativo",
                        label: "Ativo"
                    },
                    {
                        id: "em-revisao",
                        label: "Em Revisão"
                    },
                    {
                        id: "bloqueado",
                        label: "Bloqueado"
                    },
                    {
                        id: "cancelado",
                        label: "Cancelado"
                    },
                    {
                        id: "revisado",
                        label: "Revisado"
                    },
                ]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
