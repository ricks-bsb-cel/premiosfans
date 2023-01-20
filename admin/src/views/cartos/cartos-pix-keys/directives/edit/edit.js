'use strict';

const ngModule = angular.module('views.cartos-pix-keys.edit', [])

    .controller('cartosPixKeysEditController',
        function (
            $uibModalInstance,
            appDatabaseHelper,
            data
        ) {
            var $ctrl = this;

            $ctrl.ready = false;
            $ctrl.error = false;
            $ctrl.data = data;

            const key = $ctrl.data.key.replace(/[@.]/g, "-");
            const path = `pixStore/${key}/config`;

            $ctrl.rows = [];

            appDatabaseHelper.get(path)
                .then(data => {
                    data = data || {};
                    
                    $ctrl.data.merchantCity = data.merchantCity || null;
                    $ctrl.data.additionalInfo = data.additionalInfo || null;

                    Object.keys(data.generate || {}).forEach(v => {
                        $ctrl.rows.push({
                            valor: parseFloat((parseInt(v) / 100).toFixed(2)),
                            qtdMinima: data.generate[v].qtdMinima,
                            qtdMaxima: data.generate[v].qtdMaxima
                        })
                    })

                    $ctrl.ready = true;
                })
                .catch(e => {
                    console.error(e);
                })

            $ctrl.add = _ => {
                $ctrl.rows.push({
                    valor: 0,
                    qtdMinima: 10,
                    qtdMaxima: 50
                });
            }

            $ctrl.remover = index => {
                $ctrl.rows.splice(index, 1);
            }

            $ctrl.cancel = function () {
                $uibModalInstance.dismiss();
            };

            $ctrl.fields = [
                {
                    key: 'merchantCity',
                    templateOptions: {
                        label: 'Cidade Vendedor',
                        type: 'text',
                        required: true,
                        maxlength: 32
                    },
                    type: 'input',
                    className: 'col-6'
                },
                {
                    key: 'additionalInfo',
                    templateOptions: {
                        label: 'Informações Adicionais',
                        type: 'text',
                        required: true,
                        maxlength: 37
                    },
                    type: 'input',
                    className: 'col-6'
                },
            ];

            $ctrl.ok = _ => {
                if ($ctrl.data.merchantCity && $ctrl.data.merchantCity.length > 32) {
                    return alertFactory.error('O campo de Cidade do Vendedor não pode ter mais do que 32 posições', 'Dados inválidos');
                }

                if ($ctrl.data.additionalInfo && $ctrl.data.additionalInfo.length > 37) {
                    return alertFactory.error('O campo de Informações Adicionais não pode ter mais do que 37 posições', 'Dados inválidos');
                }

                const data = {
                    key: $ctrl.data.key,
                    accountId: $ctrl.data.accountId,
                    cpf: $ctrl.data.cpf,
                    type: $ctrl.data.type,
                    merchantCity: $ctrl.data.merchantCity || null,
                    additionalInfo: $ctrl.data.additionalInfo || null,
                    generate: {}
                };

                $ctrl.rows.forEach(r => {
                    data.generate[((r.valor * 100).toFixed(0)).toString()] = {
                        qtdMinima: r.qtdMinima,
                        qtdMaxima: r.qtdMaxima
                    }
                })

                if (Object.keys(data.generate) === 0) data = null;

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
