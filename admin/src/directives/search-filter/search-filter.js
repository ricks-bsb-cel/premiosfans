'use strict';

let ngModule;

ngModule = angular.module('directives.search-filter', [])

    .controller('searchFilterController',
        function (
            $scope,
            $timeout,
            entidadesFactory,
            collectionAdmConfigPath,
            path
        ) {

            $scope.ready = false;

            $scope.fields = [
                {
                    key: 'search',
                    type: 'input',
                    className: 'col-12',
                    templateOptions: {
                        type: 'text',
                        minlength: 3,
                        maxlength: 64
                    }
                }
            ];

            $scope.search = null;
            $scope.isInvalid = false;

            $scope.label = null;
            $scope.icon = null;

            $scope.model = {
                search: null
            }

            const ready = _ => {
                $timeout(_ => {
                    $scope.ready = true;
                })
            }

            const loadType = _ => {
                entidadesFactory.getConfig($scope.type)
                    .then(getConfigResult => {
                        $scope.config = getConfigResult;

                        $scope.label = getConfigResult.type.label;
                        $scope.icon = getConfigResult.path.icon;

                        ready();
                    })
                    .catch(e => {
                        console.error(e);
                    })
            }

            const loadLabel = _ => {
                const configPath = path.getCurrent();

                if (configPath.id) {
                    const sideBarLink = $(".sidebar").find(`[data-id='${configPath.id}']`);

                    if (sideBarLink.length) {
                        $scope.label = configPath.label || sideBarLink.data("label");
                        $scope.icon = sideBarLink.data("icon");
                    } else {
                        collectionAdmConfigPath.getById(configPath.id)
                            .then(doc => {
                                $scope.label = doc.label;
                                $scope.icon = doc.icon;
                            })
                            .catch(e => {
                                console.error(e);
                            })
                    }
                }

                ready();
            }

            $scope.ok = function () {
                if ($scope.loading) { return; }

                const termo = ($scope.model.search || '').toLowerCase().trim();

                if (termo.length > 0 && termo.length < 3) {
                    $scope.isInvalid = true;
                    return;
                }

                $scope.isInvalid = termo.length == 0;
                $scope.filter.run(termo);
            };

            if ($scope.type) {
                loadType();
            } else {
                loadLabel();
            }

        })

    .directive('searchFilter', function () {
        return {
            restrict: 'E',
            templateUrl: 'search-filter/search-filter.html',
            controller: 'searchFilterController',
            scope: {
                filter: '=?',
                type: '=?',
                title: '=?'
            }
        };
    });

export default ngModule;
