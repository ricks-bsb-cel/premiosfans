const ngModule = angular.module('admin.formly.ng-selector-perfis', [])
    .run(function (
        formlyConfig
    ) {
        const fieldObj = {
            name: 'ng-selector-pix-keys',
            extends: 'input',
            templateUrl: 'ng-selector-pix-keys/ng-selector-pix-keys.html',
            controller: function ($scope, collectionCartosPixKeys) {
                $scope.pixKeys = collectionCartosPixKeys;

                $scope.changed = (newValue, oldValue) => {
                    $scope.model[$scope.options.key + '_accountId'] = newValue.accountId;
                    $scope.model[$scope.options.key + '_cpf'] = newValue.cpf;
                    $scope.model[$scope.options.key + '_type'] = newValue.type;
                }
            }
        };

        formlyConfig.setType(fieldObj);
    });

export default ngModule;
