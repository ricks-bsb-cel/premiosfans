const ngModule = angular.module('admin.formly.mask-number', [])

    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'mask-number',
            extends: 'input',
            templateUrl: 'mask-number/mask-number.html',
            controller: function ($scope, $timeout) {
                var id = $scope.options.id + "_mask_number";
                $timeout(function () {
                    var e = document.getElementById(id);
                    VMasker(e).maskNumber();
                }, 500)
            }
        }

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
