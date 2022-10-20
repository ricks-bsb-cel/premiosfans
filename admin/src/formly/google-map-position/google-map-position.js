
const ngModule = angular.module('admin.formly.google-map-position', [])

    .run(function (
        formlyConfig,
        URLs,
        googleDetails
    ) {

        // https://github.com/ghiden/angucomplete-alt
        // https://developers.google.com/places/web-service/autocomplete

        var fieldObj = {
            name: 'google-map-position',
            extends: 'input',
            templateUrl: 'google-map-position/google-map-position.html',
            controller: function ($scope, $http, $timeout) {

                var mapObj = null;
                var mapId = 'google-maps-position-' + $scope.options.key;

                if ($scope.model[$scope.options.key]) {
                    $scope.initialData = {
                        description: $scope.model[$scope.options.key]
                    };
                }

                $scope.searchPlace = function (userInputString) {

                    var request = {
                        term: userInputString
                    };

                    if (_config.idSite) {
                        request.idSite = _config.idSite;
                    }

                    return $http({
                        method: 'post',
                        url: URLs.google.autocomplete,
                        data: request
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
                                    $scope.model[$scope.options.key + '_place_id'] = data.originalObject.place_id;
                                    $scope.model[$scope.options.key + '_details'] = result;
                                    $scope.model[$scope.options.key + '_exibicao'] = data.originalObject.description;

                                    enableMap(result.geometry.location);
                                },
                                error: function (e) {
                                    console.error(e);
                                }
                            }
                        )
                    }

                }

                var enableMap = function (location) {
                    mapObj.setCenter(location);
                    mapObj.setZoom(location.zoom || 14);

                    mapObj.zoomControl = true;
                    mapObj.gestureHandling = 'cooperative';
                }

                var initGoogleMap = function () {
                    // https://developers.google.com/maps/documentation/javascript/events
                    // https://developers.google.com/maps/documentation/javascript/examples/control-options

                    mapObj = new google.maps.Map(document.getElementById(mapId), {
                        center: {
                            lat: -14.837678109464894,
                            lng: -56.08548675304283
                        },
                        zoom: 3,
                        disableDefaultUI: true,
                        streetViewControl: false
                    });

                    mapObj.zoomControl = false;
                    mapObj.gestureHandling = 'none';

                    mapObj.addListener("idle", function () {
                        if ($scope.model[$scope.options.key + '_details'] && $scope.model[$scope.options.key + '_details'].geometry) {
                            $scope.model[$scope.options.key + '_details'].geometry.location = mapObj.getCenter().toJSON();
                            $scope.model[$scope.options.key + '_details'].geometry.location.zoom = mapObj.zoom;
                        }
                    });

                    if ($scope.model[$scope.options.key] && $scope.model[$scope.options.key + '_details']) {
                        enableMap($scope.model[$scope.options.key + '_details'].geometry.location);
                    }

                }

                $scope.htmlEditorOptions = {
                    height: 100,
                    lang: 'pt-BR',
                    disableDragAndDrop: true,
                    disableResizeEditor: true,
                    toolbar: [
                        ['font', ['bold', 'underline', 'clear']],
                        ['insert', ['link']],
                        ['view', ['fullscreen']]
                    ]
                }

                $timeout(function () {
                    initGoogleMap();
                })

            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
