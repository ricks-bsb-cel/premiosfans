'use strict';

let ngModule = angular.module('view.usuarios.perfil-empresa', [])

    .controller('usuarioPerfilEmpresaController',
        function (
            $scope
        ) {

            $scope.fields = [
                {
                    key: 'idEmpresa',
                    className: 'col-7',
                    templateOptions: {
                        required: true
                    },
                    type: 'ng-selector-empresa'
                },
                {
                    key: 'idPerfil',
                    className: 'col-5',
                    templateOptions: {
                        required: true
                    },
                    type: 'ng-selector-perfis'
                }
            ];

            $scope.removeEmpresa = function () {
                $scope.delegate.removeEmpresa($scope.model, $scope.pos)
            }

            $scope.setEmpresa = function () {
                $scope.delegate.setEmpresa($scope.model, $scope.pos)
            }

        })

    .directive('blockUsuarioPerfilEmpresa', function () {
        return {
            restrict: 'E',
            templateUrl: 'usuarios/directives/perfil-empresa/perfil-empresa.html',
            controller: 'usuarioPerfilEmpresaController',
            scope: {
                model: '=',
                delegate: '=',
                pos: '=',
                idEmpresaAtual: '='
            }
        };
    });

export default ngModule;
