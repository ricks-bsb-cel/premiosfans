const ngModule = angular.module('formly.telefone', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'telefone',
            extends: 'input',
            templateUrl: 'telefone/telefone.html',
            controller: function ($scope, $timeout, appConfig) {

                var id = $scope.options.id + "_telefone";

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
                    var telMask = [
                        appConfig.get("/masks/telefone"),
                        appConfig.get("/masks/celular")
                    ];
                    VMasker(e).maskPattern(telMask[0]);
                    e.addEventListener('input', inputHandler.bind(undefined, telMask, 14), false);
                })

            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
