const ngModule = angular.module('admin.formly.empresa', [])

    .run(function (
        formlyConfig
    ) {

        const fieldObj = {
            name: 'empresa',
            extends: 'input',
            templateUrl: 'empresa/empresa.html',
            controller: function ($scope, appAuthHelper) {
                appAuthHelper.ready().then(_ => {
                    $scope.model[$scope.options.key] = appAuthHelper.profile.user.empresaAtual.id;
                    $scope.nomeEmpresa = appAuthHelper.profile.user.empresaAtual.nome;
                })
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
