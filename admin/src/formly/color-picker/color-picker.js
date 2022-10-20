
const ngModule = angular.module('admin.formly.color-picker', [])

    .run(function (
        formlyConfig
    ) {

        // color-picker from https://ruhley.github.io/angular-color-picker/
        // https://baijs.com/tinycolorpicker/
        var fieldObj = {
            name: 'color-picker',
            templateUrl: 'color-picker/color-picker.html',
            controller: function (
                $scope,
                $timeout,
                globalFactory,
                formlyFactory
            ) {

                $scope.rgb = _.get($scope.model, $scope.options.key);

                $scope.colorHex = globalFactory.rgbToHex($scope.rgb);

                if (typeof $scope.to.alpha == 'undefined') {
                    $scope.to.alpha = true;
                    $scope.transpValue = globalFactory.rgbAlpha($scope.rgb);
                } else {
                    $scope.transpValue = 1;
                }

                $scope.transpList = $scope.options.data.transpList || [
                    { label: 'Opaco', value: 1 },
                    { label: '75%', value: 0.75 },
                    { label: '50%', value: 0.5 },
                    { label: '25%', value: 0.25 },
                    { label: '10%', value: 0.1 },
                    { label: 'Transparente', value: 0 }
                ];

                $scope.transp = null;
                $scope.transpList.forEach(function (t) {
                    if (!$scope.transp && $scope.transpValue >= t.value) {
                        $scope.transp = t.label;
                        $scope.transpValue = t.value;
                    }
                });

                $scope.setModel = function () {
                    var rgb = globalFactory.hexToRgb($scope.colorHex);
                    var rgba = 'rgba(' + rgb.r + ',' + rgb.g + ',' + rgb.b + ',' + $scope.transpValue + ')';
                    _.set($scope.model, $scope.options.key, rgba);
                };

                $scope.setTransp = function (t) {
                    $scope.transp = t.label;
                    $scope.transpValue = t.value;
                    $scope.setModel();
                }

                $scope.initColorPick = function (elem) {

                    $scope.colorPickerEl = elem.find('.picker');
                    $scope.colorPickerInput = elem.find('input');

                    $scope.colorPickerEl.colorPick({
                        initialColor: $scope.colorHex,
                        allowRecent: true,
                        recentMax: 5,
                        allowCustomColor: false,
                        paletteLabel: 'Cores',
                        recentLabel: 'Recentes',
                        palette: formlyFactory.getPalette(),
                        onColorSelected: function () {
                            var self = this;
                            $scope.colorPickerInput.val(self.color);

                            $timeout(function () {
                                $scope.colorHex = self.color;
                                $scope.setModel();
                            })
                        }
                    });

                    $scope.colorPickerInput.change(function () {
                        var color = this.value;
                        $timeout(function () {
                            $scope.colorHex = color;
                            $scope.setModel();
                        })
                    })
                }

            },
            link: (scope, elem) => {
                scope.initColorPick(elem);
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
