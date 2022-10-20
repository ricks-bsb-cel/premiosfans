'use strict';

const ngModule = angular.module('collection.contratosProdutos', [])

    .factory('collectionContratosProdutos', function (
        appCollection,
        appAuthHelper,
        collectionProdutos,
        globalFactory,
        $q
    ) {

        const attr = {
            collection: 'contratosProdutos',
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const getProdutosContrato = (idContrato, idCliente) => {
            return $q((resolve, reject) => {

                let produtosContrato,
                    idProdutos = [];

                return appAuthHelper.ready()

                    .then(_ => {

                        return firebaseCollection.query([
                            { field: "idEmpresa", operator: "==", value: appAuthHelper.profile.user.idEmpresa },
                            { field: "idContrato", operator: "==", value: idContrato },
                            { field: "idCliente", operator: "==", value: idCliente }
                        ]);

                    })

                    .then(resultContratoProdutos => {
                        produtosContrato = resultContratoProdutos;

                        let promiseProdutos = [];

                        resultContratoProdutos.forEach(p => {
                            if (!idProdutos.includes(p.idProduto)) {
                                idProdutos.push(p.idProduto);
                                promiseProdutos.push(collectionProdutos.getById(p.idProduto));
                            }
                        })

                        return Promise.all(promiseProdutos);
                    })

                    .then(resultPromiseProdutos => {

                        produtosContrato.forEach((p, i) => {

                            p.tipo = p.tipoCobranca;
                            p.qtd = p.qtdParcelas || 1;

                            p.vlTotal = (p.tipo === 'am' ? p.valor : p.qtdParcelas * p.valor);

                            let pos = resultPromiseProdutos.findIndex(f => {
                                return f.id === p.idProduto;
                            })

                            if (pos >= 0) {
                                produtosContrato[i].nome = resultPromiseProdutos[pos].nome;
                                produtosContrato[i].codigo = resultPromiseProdutos[pos].codigo;
                                produtosContrato[i].descricao = resultPromiseProdutos[pos].descricao;
                            }
                        })

                        produtosContrato = globalFactory.sortArray(produtosContrato, 'pos');

                        return resolve(produtosContrato);
                    })

                    .catch(e => {
                        return reject(e);
                    })
            })
        }

        return {
            collection: firebaseCollection,
            getProdutosContrato: getProdutosContrato
        };
    })

export default ngModule;
