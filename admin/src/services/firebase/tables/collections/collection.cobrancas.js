'use strict';

const ngModule = angular.module('collection.cobrancas', [])

    .factory('collectionCobrancas', function (
        appErrors,
        appFirestore,
        appAuthHelper,
        appCollection,
        blockUiFactory,
        alertFactory,
        URLs,
        $http,
        $q
    ) {

        const attr = {
            collection: 'cobrancas',
            autoStartSnapshot: false,
            filterEmpresa: true,

            eachRow: function (row) {

                const momentDtHoje = moment(appFirestore.Timestamp.now().toDate()).hour(0).minute(0).second(0);
                const momentDtInclusao = moment(row.dtInclusao_timestamp.toDate()).hour(0).minute(0).second(0);
                const momentDtVencimento = moment(row.dtVencimento_timestamp.toDate()).hour(0).minute(0).second(0);

                const totalDiasDisponiveisParaPagamento = momentDtVencimento.diff(momentDtInclusao, 'days');
                const diasRestantesParaPagamento = momentDtVencimento.diff(momentDtHoje, 'days');

                row.totalDiasDisponiveisParaPagamento = totalDiasDisponiveisParaPagamento;
                row.diasRestantesParaPagamento = diasRestantesParaPagamento;

                if (row.diasRestantesParaPagamento < 0) {
                    row.diasEmAtraso = Math.abs(row.diasRestantesParaPagamento);
                }

                row.percentualDiasDisponiveisParaPagamento = Math.trunc((diasRestantesParaPagamento / totalDiasDisponiveisParaPagamento) * 100);

                return row;
            }
        }

        const firebaseCollection = new appCollection(attr);

        const save = function (data) {

            blockUiFactory.start();

            var data = {
                idCliente: data.idCliente,
                idContrato: data.idContrato || null,
                idPlano: data.idPlano || null,
                dtVencimento: moment(data.dtVencimento_timestamp.toDate()).format("YYYY-MM-DD"),
                valor: data.valor
            }

            const httpParms = {
                url: URLs.cobrancas.create,
                method: 'post',
                data: data,
                headers: { 'Authorization': 'Bearer ' + appAuthHelper.token }
            };

            return $q((resolve, reject) => {

                $http(httpParms).then(
                    function (response) {
                        blockUiFactory.stop();
                        return resolve(response);
                    },
                    function (e) {
                        blockUiFactory.stop();
                        if (e.data && e.data.error) {
                            alertFactory.error(e.data.error);
                        }
                        return reject(e);
                    }
                );

            })

        }

        const deleteFakeData = function (idEmpresa, confirm, callback) {
            firebaseCollection.removeFakeData(idEmpresa, confirm, callback);
        }

        return {
            collection: firebaseCollection,
            save: save,
            deleteFakeData: deleteFakeData
        };

    });

export default ngModule;
