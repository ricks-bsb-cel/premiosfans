'use strict';

const ngModule = angular.module('views.cartos-pix-keys.edit', [])

    .controller('cartosPixKeysEditController',
        function (
            $uibModalInstance,
            appDatabaseHelper,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = true;
            $ctrl.error = false;
            $ctrl.data = data;

            const key = $ctrl.data.key.replace(/[@.]/g, "-");
            const path = `pixAntecipado/${key}`;

            $ctrl.rows = [];

            appDatabaseHelper.get(path)
                .then(data => {
                    $ctrl.rows = data.generate;
                })
                .catch(e => {
                    console.error(e);
                })

            $ctrl.add = _ => {
                $ctrl.rows.push({
                    valor: 0,
                    qtd: 100
                });
            }

            $ctrl.remover = index => {
                $ctrl.rows.splice(index, 1);
            }

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };

            $ctrl.ok = _ => {
                const data = {
                    key: $ctrl.data.key,
                    accountId: $ctrl.data.accountId,
                    cpf: $ctrl.data.cpf,
                    type: $ctrl.data.type,
                    generate: $ctrl.rows.map(r => {
                        return {
                            valor: r.valor,
                            qtd: r.qtd
                        }
                    })
                };

                if (!data.generate || data.generate.length === 0) data = null;

                appDatabaseHelper.set(path, data)
                    .then(_ => {
                        $uibModalInstance.close($ctrl.data);
                    })
                    .catch(e => {
                        console.error(e);
                    })
            }

        })

    .factory('cartosPixKeysEditFactory',
        function (
            $q,
            $uibModal
        ) {

            var showModal = function (e) {
                return $q(function (resolve, reject) {
                    var modal = $uibModal.open({
                        windowClass: 'cartos-pix-keys-edit-modal',
                        templateUrl: 'cartos/cartos-pix-keys/directives/edit/edit.html',
                        controller: 'cartosPixKeysEditController',
                        controllerAs: '$ctrl',
                        size: 'lg',
                        backdrop: false,
                        resolve: {
                            data: function () {
                                return e;
                            }
                        }
                    });

                    modal.result.then(function (data) {
                        resolve(data);
                    }, function () {
                        reject();
                    });

                })
            }

            var edit = function (original) {

                var toEdit = angular.copy(original);

                return $q(function (resolve, reject) {
                    showModal(toEdit).then(function (updated) {
                        original = updated;
                        resolve(original);
                    }).catch(function () {
                        reject();
                    })
                })
            }

            return {
                edit: edit
            };;
        }
    );

export default ngModule;
