
const ngModule = angular.module('admin.formly.google-auto-complete', [])

    .run(function (
        formlyConfig,
        googleDetails
    ) {

        // https://github.com/ghiden/angucomplete-alt

        var fieldObj = {
            name: 'google-auto-complete',
            extends: 'input',
            templateUrl: 'google-auto-complete/google-auto-complete.html',
            controller: function ($scope, $http) {

                $scope.initialData = {
                    description: $scope.model[$scope.options.key + '_cidade_uf'] || null
                };
    
                $scope.searchPlace = function (userInputString) {
                    return $http({
                        method: 'post',
                        url: '/api/v1/maps/place/autocomplete',
                        data: { term: userInputString }
                    });
                }
    
                $scope.selected = function (data) {
    
                    if (!data) { return; }
    
                    if (data.originalObject) {
                        $scope.model[$scope.options.key] = data.originalObject.description;
                    }
    
                    if (data.originalObject.place_id) {
    
                        googleDetails.get(
                            {
                                place_id: data.originalObject.place_id,
                                success: function (result) {
                                    setModel(result);
                                    console.info(result);
                                },
                                error: function (e) {
                                    console.error(e);
                                }
                            }
                        )
    
                    }
    
                }
    
                var setModel = function (data) {
    
                    $scope.model[$scope.options.key + '_place'] = data;
                    $scope.model[$scope.options.key + '_place_id'] = data.place_id;
    
                    // Compatibilidade
                    $scope.model[$scope.options.key + '_cidade_uf'] = data._cidade + '/' + data._uf;
                    $scope.model[$scope.options.key + '_cidade'] = data._cidade;
                    $scope.model[$scope.options.key + '_uf'] = data._uf;
                    $scope.model[$scope.options.key + '_key'] = data.place_id;
                }
    
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
