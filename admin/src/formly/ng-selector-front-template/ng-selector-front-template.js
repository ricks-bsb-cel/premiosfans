const ngModule = angular.module('admin.formly.ng-selector-front-template', [])
    // https://www.npmjs.com/package/angular-selector
    .run(function (
        formlyConfig
    ) {

        var fieldObj = {
            name: 'ng-selector-front-template',
            extends: 'input',
            templateUrl: 'ng-selector-front-template/ng-selector-front-template.html',
            controller: function ($scope, appAuthHelper, collectionFrontTemplates) {
                $scope.collectionFrontTemplates = collectionFrontTemplates;

                $scope.init = _ => {
                    appAuthHelper.ready()
                        .then(_ => {
                            $scope.collectionFrontTemplates.collection.startSnapshot({
                                filter: [{ field: "ativo", operator: "==", value: true }]
                            });
                        })
                }

            },
            link: function (scope) {
                scope.init();
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
