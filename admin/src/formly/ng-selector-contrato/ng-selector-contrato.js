const ngModule = angular.module('admin.formly.ng-selector-contrato', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-contrato',
            extends: 'input',
            templateUrl: 'ng-selector-contrato/ng-selector-contrato.html',
            controller: function ($scope, appAuthHelper, $http, URLs, globalFactory) {

                const avulso = {
                    id: 'avulso',
                    plano: { nome: 'Avulso', ativo: true }
                };

                $scope.data = [avulso];
                $scope.ready = false;
                $scope.model[$scope.options.key] = $scope.model[$scope.options.key] || avulso.id;

                const load = idCliente => {

                    $scope.ready = false;

                    const httpParms = {
                        url: URLs.contratos.get + "?idCliente=" + idCliente + "&load-reference=idPlano_reference&v=" + globalFactory.generateRandomId(16),
                        method: 'get',
                        headers: {
                            Authorization: appAuthHelper.token
                        }
                    };

                    $http(httpParms).then(
                        function (response) {

                            var data = [avulso];

                            if (response.data.rows) {
                                data.push(...response.data.rows);
                            } else if (response.data.data) {
                                data.push(response.data.data);
                            }

                            $scope.data = data;
                            $scope.ready = true;

                        },
                        function (e) {
                            console.error(e);
                        }
                    );

                }

                $scope.changed = (newValue, oldValue) => {
                    if ($scope.options.data.idPlanoField && newValue.idPlano) {
                        $scope.model[$scope.options.data.idPlanoField] = newValue.idPlano;
                    }
                }

                $scope.$watch('model', function (newValue, oldValue) {
                    const newIdCliente = newValue[$scope.options.data.idClienteField] || null;
                    const oldIdCliente = oldValue[$scope.options.data.idClienteField] || null;
                    if (newIdCliente && newIdCliente !== oldIdCliente) {
                        load(newIdCliente);
                    }
                }, true)

                if ($scope.model[$scope.options.data.idClienteField]) {
                    load($scope.model[$scope.options.data.idClienteField])
                }

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
