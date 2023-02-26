const ngModule = angular.module('formly.data', [])

    .run(function (
        formlyConfig
    ) {

        formlyConfig.setType({
            name: 'data',
            extends: 'input',
            templateUrl: 'data/data.html',
            controller: function ($scope, $timeout, appFirestoreHelper) {

                $scope.id = $scope.options.id + "_data";
                $scope.appFirestoreHelper = appFirestoreHelper;

                const set = value => {

                    const patternYMD = /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/g; // YYYY-MM-DD
                    const patternDMY = /^([0]?[1-9]|[1|2][0-9]|[3][0|1])[./-]([0]?[1-9]|[1][0-2])[./-]([0-9]{4}|[0-9]{2})$/g;

                    // Transforma a data para o caso dela estar em YYYY-MM-DD
                    if (patternYMD.test(value)) { $scope.value = moment(value, 'YYYY-MM-DD').format('DD/MM/YYYY'); }
                    if (patternDMY.test(value)) { $scope.value = value; }

                }

                if ($scope.model[$scope.options.key]) {
                    set($scope.model[$scope.options.key]);
                }

                if (!$scope.value) {
                    const unWatch = $scope.$watch('model', (newValue, oldValue) => {
                        if (newValue[$scope.options.key]) {
                            set(newValue[$scope.options.key]);
                            unWatch();
                        }
                    }, true);
                }

                $timeout(_ => {
                    const e = document.getElementById($scope.id);
                    VMasker(e).maskPattern('99/99/9999');
                })

            },
            defaultOptions: {
                validators: {
                    isValidDate: {
                        expression: (newValue, oldValue, scope) => {

                            const setInvalid = _ => {
                                scope.model[scope.options.key] = null;
                                scope.model[scope.options.key + '_timestamp'] = null;
                                scope.model[scope.options.key + '_yyyymmdd'] = null;

                                scope.form.$setValidity(scope.options.key, false);

                                return false;
                            }

                            if (newValue && newValue.length == 10) {

                                var d = moment(newValue, "DD/MM/YYYY");

                                if (d.isValid()) {
                                    scope.model[scope.options.key] = newValue;

                                    scope.model[scope.options.key + '_timestamp'] = scope.appFirestoreHelper.toTimestamp(d.toDate());
                                    scope.model[scope.options.key + '_yyyymmdd'] = d.format('YYYY-MM-DD');

                                    scope.form.$setValidity(scope.options.key, true);

                                    return true;
                                } else {
                                    return setInvalid();
                                }
                            } else {
                                return setInvalid();
                            }
                        },
                        message: function () {
                            return 'Data inválida';
                        }
                    }
                }
            }
        });

    });

export default ngModule;
