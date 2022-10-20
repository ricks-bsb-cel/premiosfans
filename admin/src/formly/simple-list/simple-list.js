const ngModule = angular.module('admin.formly.simple-list', [])

    .run(function (
        formlyConfig,
        globalFactory,
        alertFactory
    ) {

        var fieldObj = {
            name: 'simple-list',
            extends: 'input',
            templateUrl: 'simple-list/simple-list.html',
            controller: function ($scope, $timeout) {

                if (!$scope.model[$scope.options.key] || $scope.model[$scope.options.key].constructor !== Array) {
                    $scope.model[$scope.options.key] = [];
                }

                $scope.add = function () {
                    $scope.model[$scope.options.key].push({
                        id: globalFactory.guid(),
                        descricao: null,
                        order: ($scope.model[$scope.options.key].length + 1) * 10
                    });
                }

                $scope.delete = function (row) {
                    alertFactory.yesno('Tem certeza que deseja remover o item?').then(function () {
                        $scope.model[$scope.options.key] = $scope.model[$scope.options.key].filter(function (r) {
                            return r.id != row.id;
                        })
                    }).catch(function () { });
                }

                $scope.changeOrder = function (a, b) {
                    var currentOrder = a.order;
                    var otherOrder = b.order;

                    a.order = otherOrder;
                    b.order = currentOrder;
                }

                if ($scope.model[$scope.options.key].length == 0) {
                    $scope.add();
                }

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
