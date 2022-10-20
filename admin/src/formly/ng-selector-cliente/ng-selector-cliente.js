const ngModule = angular.module('admin.formly.ng-selector-clientes', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        let fieldObj = {
            name: 'ng-selector-cliente',
            extends: 'input',
            templateUrl: 'ng-selector-cliente/ng-selector-cliente.html',
            controller: function ($scope, $http, $q, appAuthHelper, toastrFactory, globalFactory, URLs) {

                const keys = ['celular', 'celular_formatted', 'celular_int', 'celular_intplus', 'cnpj', 'cnpj_formatted', 'cpf', 'cpf_formatted', 'cpfcnpj', 'cpfcnpj_formatted', 'cpfcnpj_type', 'nome', 'email'];
                let url = URLs.collections.clientes,
                    initiated = false,
                    prefixo = ($scope.to.data ? $scope.to.data.prefixo || '' : '');

                $scope.model[$scope.options.key] = $scope.model[$scope.options.key] || null;
                $scope.clientes = [];

                $scope.isDisabled = function () {
                    return $scope.options.ngModelElAttrs && $scope.options.ngModelElAttrs.disabled === 'true';
                }

                const options = {
                    url: url,
                    cache: false,
                    headers: {
                        Authorization: 'Bearer ' + appAuthHelper.token // Será renovado antes da consulta
                    },
                    transformResponse: data => {
                        var result = angular.fromJson(data);

                        if (result.rows) {
                            $scope.clientes = result.rows;
                        } else if (result.data) {
                            $scope.clientes = [result.data];
                            // $scope.model[$scope.options.key] = result.data.id;
                        } else {
                            $scope.clientes = [];
                        }

                        return $scope.clientes;
                    }
                };

                $scope.doSearch = function (search) {
                    var httpOptions = angular.merge(options);
                    httpOptions.headers.Authorization = 'Bearer ' + appAuthHelper.token;

                    if (!search || search.length < 3) {
                        if (!initiated && $scope.model[$scope.options.key] && $scope.model[$scope.options.key].length) {
                            initiated = true;
                            httpOptions.url = url + "?id=" + $scope.model[$scope.options.key] + "&v=" + globalFactory.generateRandomId(16)
                            return $http(httpOptions);
                        }
                        else {
                            return $q.resolve([]);
                        }
                    };

                    httpOptions.url = url + "?search=" + search + "&v=" + globalFactory.generateRandomId(16);

                    return $http(httpOptions);
                }

                $scope.changed = (newValue, oldValue) => {
                    if (!newValue && oldValue) {
                        keys.forEach(k => {
                            if ($scope.model[prefixo + k]) {
                                $scope.model[prefixo + k] = null;
                            }
                        })
                    }

                    if (newValue && !oldValue) {
                        keys.forEach(k => {
                            if (newValue[k]) {
                                $scope.model[prefixo + k] = newValue[k];
                            }
                        })
                    }
                }

                $scope.$watch('model', function (newValue, oldValue) {
                    if (newValue[$scope.options.key] && newValue[prefixo + 'nome']) {
                        $scope.clientes = [
                            {
                                id: newValue[$scope.options.key],
                                nome: newValue[prefixo + 'nome']
                            }
                        ]
                    }
                }, true);

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
