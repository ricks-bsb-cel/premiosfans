const ngModule = angular.module('admin.formly.ng-selector', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector',
            extends: 'input',
            templateUrl: 'ng-selector/ng-selector.html',
            controller: function ($scope, alertFactory, collectionsFormlySelector, $q, $timeout) {

                if (!$scope.options.templateOptions.collection) {
                    alert('Erro de programação! Atributo collection não informado...');
                }

                $scope.id = $scope.options.id + "-ng-selector";
                $scope.selectorOptions = [];
                $scope.multiselect = typeof $scope.options.templateOptions.multiselect === 'boolean' ? $scope.options.templateOptions.multiselect : false;
                $scope.model[$scope.options.key] = $scope.model[$scope.options.key] || [];

                $scope.ready = false;

                collectionsFormlySelector
                    .get($scope.options.templateOptions.collection)
                    .then(data => {
                        $scope.selectorOptions = data;

                        $timeout(function () {
                            $scope.ready = true;
                        })
                    });

                $scope.createNewItem = function (input) {
                    var deferred = $q.defer();

                    alertFactory.yesno('Tem certeza que deseja criar o item<br/><strong>"' + input + '</strong>"?').then(function () {

                        collectionsFormlySelector
                            .create($scope.options.templateOptions.collection, input)
                            .then(data => {
                                $scope.model[$scope.options.key] = data.id;
                                deferred.resolve({ value: data.id, label: data.label });
                            })
                            .catch(e => {
                                console.error(e);
                            })

                    }).catch(function () {
                        deferred.reject();
                    })

                    return deferred.promise;
                }

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
