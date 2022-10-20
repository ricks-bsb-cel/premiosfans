const ngModule = angular.module('admin.formly.data-mm-yyyy', [])

    .run(function (
        formlyConfig
    ) {

        formlyConfig.setType({
            name: 'data-mmyyyy',
            extends: 'input',
            templateUrl: 'data-mm-yyyy/data-mm-yyyy.html',
            controller: function ($scope, appFirestoreHelper, $timeout, toastrFactory) {
                $scope.value = $scope.model[$scope.options.key] || null;
                $scope.id = $scope.options.id + "-data-mm-yyyy";

                const setModelValid = d => {
                    $scope.model[$scope.options.key + '_mmyyyy'] = d.format('MM/YYYY');
                    $scope.model[$scope.options.key + '_mes'] = d.month() + 1;
                    $scope.model[$scope.options.key + '_ano'] = d.year();
                    $scope.model[$scope.options.key + '_timestamp'] = appFirestoreHelper.toTimestamp(d.toDate());

                    $scope.form.$setValidity($scope.options.key, true);
                }

                const setModelInvalid = _ => {
                    delete $scope.model[$scope.options.key + '_mmyyyy'];
                    delete $scope.model[$scope.options.key + '_mes'];
                    delete $scope.model[$scope.options.key + '_ano'];
                    delete $scope.model[$scope.options.key + '_timestamp'];

                    $scope.form.$setValidity($scope.options.key, false);
                }

                const setData = d => {
                    d = moment('01/' + d, 'DD/MM/YYYY');

                    if (d.isValid()) {
                        setModelValid(d);
                    } else {
                        setModelInvalid();

                        toastrFactory.error('Informe uma data válida no formato MM/YYYY (mês com dois dígitos e ano com quatro dígitos).');
                    }
                }

                $scope.$watch('model', function (newValue, oldValue) {
                    const nv = newValue && newValue[$scope.options.key] ? newValue[$scope.options.key] : null;
                    const ov = oldValue && oldValue[$scope.options.key] ? oldValue[$scope.options.key] : null;

                    if (nv !== ov && nv.length === 7) {
                        setData(newValue[$scope.options.key]);
                        $scope.value = newValue[$scope.options.key];
                    }
                }, true);

                $scope.$watch('value', function (newValue, oldValue) {
                    if (newValue && newValue.length === 7) {
                        setData(newValue);
                    } else {
                        setModelInvalid();
                    }
                })

                $timeout(function () {
                    var e = document.getElementById($scope.id);

                    VMasker(e).maskPattern("99/9999");
                })

            }
        });

    });

export default ngModule;
