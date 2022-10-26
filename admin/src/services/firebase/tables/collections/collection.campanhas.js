'use strict';

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        alertFactory,
        appAuthHelper,
        URLs,
        $http,
        $q
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getById = id => {
            return appFirestoreHelper.getDoc(attr.collection, id);
        }

        const save = contrato => {

            return $q((resolve, reject) => {

                if (!contrato.idCliente) {
                    alertFactory.error('Os dados do cliente devem ser informados.')
                    return reject();
                }

                // O código da empresa e userId serão carregados do token
                let payload = {
                    idCliente: contrato.idCliente,
                    inicioContrato_mes: contrato.inicioContrato_mes,
                    inicioContrato_ano: contrato.inicioContrato_ano,
                    diaMesCobranca: contrato.diaMesCobranca,
                    obs: contrato.obs,
                    guidContrato: contrato.guidContrato,
                    produtos: []
                };

                if (contrato.idContrato) payload.idContrato = contrato.idContrato;
                if (contrato.codigoContrato) payload.codigoContrato = contrato.codigoContrato;
                if (contrato.codigoContratoVersao) payload.codigoContratoVersao = contrato.codigoContratoVersao;


                contrato.produtos.forEach(p => {
                    let produto = {
                        guidProduto: p.guidProduto,
                        idProduto: p.idProduto,
                        tipoCobranca: p.tipo,
                        valor: p.valor
                    };

                    if (p.tipo === 'pa') {
                        produto.qtdParcelas = p.qtd;
                    }

                    payload.produtos.push(produto);
                });

                $http({
                    url: URLs.contratos.save,
                    method: 'post',
                    data: payload,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                }).then(
                    function (response) {
                        return resolve(response);
                    },
                    function (e) {
                        console.error(e);
                        return reject(e);
                    }
                );

            })

        }

        return {
            collection: firebaseCollection,
            getById: getById,
            save: save
        };

    });


export default ngModule;
