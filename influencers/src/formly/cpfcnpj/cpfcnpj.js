const ngModule = angular.module('formly.cpfcnpj', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'cpfcnpj',
            extends: 'input',
            templateUrl: 'cpfcnpj/cpfcnpj.html',
            controller: function ($scope, $timeout, globalFactory, appConfig) {

                var id = $scope.options.id + "_cpfcnpj";

                $scope.value = $scope.model[$scope.options.key + '_formatted'] || $scope.model['cpf_formatted'] || null;

                $scope.isValid = true;
                $scope.isEmpty = true;

                $scope.$watch('value', function (newvalue, oldvalue) {

                    var code = globalFactory.onlyNumbers(newvalue);
                    $scope.isEmpty = !code;

                    if (code.length === 11) {
                        $scope.isValid = globalFactory.isCPFValido(newvalue);
                    } else if (code.length === 14) {
                        $scope.isValid = globalFactory.isCNPJValido(newvalue);
                    } else {
                        $scope.isValid = false;
                    }

                    $scope.form.$setValidity($scope.options.key, $scope.isValid);

                    if ($scope.isValid) {
                        $scope.model[$scope.options.key] = code;
                        $scope.model[$scope.options.key + '_formatted'] = newvalue;
                        $scope.model[$scope.options.key + '_type'] = code.length == 11 ? 'PF' : 'PJ';
                    }

                });

                var inputHandler = function (masks, max, event) {
                    var c = event.target;
                    var v = c.value.replace(/\D/g, '');
                    var m = c.value.length > max ? 1 : 0;
                    VMasker(c).unMask();
                    VMasker(c).maskPattern(masks[m]);
                    c.value = VMasker.toPattern(v, masks[m]);
                }

                $timeout(function () {
                    var e = document.getElementById(id);
                    var mask = [
                        appConfig.get("/masks/cpf"),
                        appConfig.get("/masks/cnpj")
                    ];
                    VMasker(e).maskPattern(mask[($scope.value || '').length === 18 ? 1 : 0]);
                    e.addEventListener('input', inputHandler.bind(undefined, mask, 14), false);
                })

            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
