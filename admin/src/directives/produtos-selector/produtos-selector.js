'use strict';

import angular from "angular";

let ngModule = angular.module('directives.produtos-selector', [])

    .controller('produtosSelectorEditController',
        function (
            $uibModalInstance,
            collectionProdutos,
            appAuthHelper,
            globalFactory,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data || [];

            appAuthHelper.ready()
                .then(_ => {

                    let filter = [
                        { field: "idEmpresa", operator: "==", value: appAuthHelper.profile.user.idEmpresa },
                        { field: "ativo", operator: "==", value: true }
                    ];

                    collectionProdutos.collection.query(filter)
                        .then(data => {
                            $ctrl.data = globalFactory.sortArray(data, 'nome');
                            $ctrl.ready = true;
                        })
                        .catch(e => {
                            console.error(e);
                        })

                })

            $ctrl.ok = function () {
                let result = [];

                $ctrl.data.forEach(p => {
                    if (p.selected) {
                        result.push({
                            guidProduto: globalFactory.guid(),
                            idProduto: p.id,
                            codigo: p.codigo,
                            nome: p.nome,
                            valor: p.valor,
                            ativo: true,
                            qtd: 1,
                            tipo: 'pa'
                        });
                    }
                })

                $uibModalInstance.close(result);
            };

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };
        })

    .factory('produtosSelectorEditFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = data => {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'produtos-selector-modal',
                        templateUrl: 'produtos-selector/produtos-selector-edit.html',
                        controller: 'produtosSelectorEditController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return data;
                            }
                        }
                    });

                    modal.result
                        .then(data => {
                            resolve(data);
                        }, function () {
                            reject();
                        });

                })
            }

            const add = data => {
                return $q(function (resolve, reject) {
                    showModal(data)
                        .then(updated => {
                            resolve(updated);
                        })
                        .catch(function () {
                            reject();
                        })
                })
            }

            return {
                add: add
            };
        })

    .controller('produtosSelectorController',
        function (
            $scope,
            produtosSelectorEditFactory,
            appAuthHelper,
            collectionAdmConfigPath
        ) {

            $scope.produtos = $scope.produtos || [];
            $scope.titles = {};

            if (typeof $scope.disabled === 'undefined') {
                $scope.disabled = false;
            }

            const calcProduct = p => {
                if (p.tipo === 'ar') {
                    p.qtd = 1;
                }

                p.vlTotal = parseFloat((p.qtd * p.valor).toFixed(2));

                return p;
            }

            const showTitles = _ => {
                collectionAdmConfigPath.getById('H0QBd7rgbsaApsazEQbS')
                    .then(result => {
                        $scope.titles.produtos = result;
                    })
            }

            $scope.valueChanged = p => {
                p = calcProduct(p);
            }

            $scope.up = (pos) => {
                if (pos === 0) { return; }

                const [p] = $scope.produtos.splice(pos, 1);
                $scope.produtos.splice(pos - 1, 0, p);
            }

            $scope.down = (pos) => {
                if (pos === ($scope.produtos.length - 1)) { return; }

                const [p] = $scope.produtos.splice(pos, 1);
                $scope.produtos.splice(pos + 1, 0, p);
            }

            $scope.delete = (pos) => {
                $scope.produtos.splice(pos, 1)
            }

            $scope.add = _ => {
                produtosSelectorEditFactory.add($scope.produtos)
                    .then(result => {
                        result.forEach(p => {
                            $scope.produtos.push(calcProduct(p));
                        })
                    })
            }

            appAuthHelper.ready()
                .then(_ => {
                    showTitles();
                })

        })

    .directive('produtosSelector', function () {
        return {
            restrict: 'E',
            templateUrl: 'produtos-selector/produtos-selector.html',
            controller: 'produtosSelectorController',
            scope: {
                produtos: "=",
                disable: "="
            }
        };
    });

export default ngModule;
