const ngModule = angular.module('admin.formly.ng-selector-periodo-parcela', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-periodo-parcela',
            extends: 'input',
            templateUrl: 'ng-selector-periodo-parcela/ng-selector-periodo-parcela.html',
            controller: function ($scope) {

                $scope.id = $scope.options.id + "-ng-selector-periodo-parcela";

                $scope.selectOptions = [
                    {
                        id: "mensal",
                        label: "Mensal"
                    },
                    {
                        id: "bimestral",
                        label: "Bimestral"
                    },
                    {
                        id: "trimestral",
                        label: "Trimestral"
                    }
                ]
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
