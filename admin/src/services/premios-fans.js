'use strict';

const ngModule = angular.module('services.premios-fans', [])

    .factory('premiosFansService',
        function (
            appAuthHelper,
            $http,
            blockUiFactory,
            toastrFactory,
            globalFactory
        ) {

            const getUrlEndPoint = url => {
                const localUrl = 'http://localhost:5002';
                const gatewayUrl = 'https://premios-fans-a8fj1dkb.uc.gateway.dev';

                return (window.location.hostname === 'localhost' ? localUrl : gatewayUrl) + url;
            }

            const generateTemplates = attrs => {
                attrs = attrs || {
                    blockUi: true
                };

                attrs.data = attrs.data || {};

                attrs.data.idCampanha = attrs.data.idCampanha || 'all';
                attrs.data.idInfluencer = attrs.data.idInfluencer || 'all';

                if (attrs.blockUi) blockUiFactory.start();

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/generate-templates'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            if (attrs.blockUi) blockUiFactory.stop();
                            toastrFactory.info('Os templates estão sendo gerados...');
                            if (typeof attrs.success === 'function') {
                                attrs.success(response.data.data);
                            }
                        },
                        function (e) {
                            if (attrs.blockUi) blockUiFactory.stop();
                            console.error(e);
                            toastrFactory.error('Erro solicitando geração de templates...');
                            if (typeof attrs.error === 'function') {
                                attrs.error(e);
                            }
                        }
                    );
            }

            const pagarTituloCompra = attrs => {
                attrs = attrs || { blockUi: false };

                attrs.data = attrs.data || {};

                attrs.data.idTituloCompra = attrs.idTituloCompra;

                if (!attrs.data.idTituloCompra) throw new Error('Invalid parms');

                if (attrs.blockUi) blockUiFactory.start();

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/pagar-compra'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            if (attrs.blockUi) blockUiFactory.stop();

                            toastrFactory.info(`O pagamento manual da compra [${attrs.data.idTituloCompra}] está em andamento...`);

                            if (typeof attrs.success === 'function') {
                                attrs.success(response.data.data);
                            }
                        },
                        function (e) {
                            if (attrs.blockUi) blockUiFactory.stop();
                            console.error(e);
                            toastrFactory.error(`Erro solicitando o pagamento da compra [${attrs.data.idTituloCompra}]...`);
                            if (typeof attrs.error === 'function') {
                                attrs.error(e);
                            }
                        }
                    );
            }

            const checkTituloCompra = attrs => {
                attrs = attrs || { blockUi: false };

                attrs.data = attrs.data || {};

                attrs.data.idTituloCompra = attrs.idTituloCompra;

                if (!attrs.data.idTituloCompra) throw new Error('Invalid parms');

                if (attrs.blockUi) blockUiFactory.start();

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/check-titulos-compra'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            if (attrs.blockUi) blockUiFactory.stop();

                            toastrFactory.info(`A verificaçao da compra [${attrs.data.idTituloCompra}] está em andamento...`);

                            if (typeof attrs.success === 'function') {
                                attrs.success(response.data.data);
                            }
                        },
                        function (e) {
                            if (attrs.blockUi) blockUiFactory.stop();
                            console.error(e);
                            toastrFactory.error(`Erro solicitando a verificação da compra [${attrs.data.idTituloCompra}]...`);
                            if (typeof attrs.error === 'function') {
                                attrs.error(e);
                            }
                        }
                    );
            }

            const ativarCampanha = attrs => {
                attrs = attrs || { blockUi: false };

                attrs.data = attrs.data || {};

                attrs.data.idCampanha = attrs.idCampanha;

                if (!attrs.data.idCampanha) throw new Error('Invalid parms');

                if (attrs.blockUi) blockUiFactory.start();

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/ativar-campanha'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            if (attrs.blockUi) blockUiFactory.stop();

                            toastrFactory.info(`A campanha [${attrs.data.idCampanha}] está em ativação...`);

                            if (typeof attrs.success === 'function') {
                                attrs.success(response.data.data);
                            }
                        },
                        function (e) {
                            if (attrs.blockUi) blockUiFactory.stop();
                            console.error(e);
                            toastrFactory.error(`Erro solicitando ativação da campanha [${attrs.data.idCampanha}]...`);
                            if (typeof attrs.error === 'function') {
                                attrs.error(e);
                            }
                        }
                    );
            }

            const refreshCartosPixKeys = attrs => {
                if (!attrs.data.cpf || !attrs.data.accountId) throw new Error('Invalid parms');

                toastrFactory.info(`Solicitando atualizações de Chaves PIX...`);

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/cartos/update-pix-keys?async=true'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            toastrFactory.info(`Atualização de Chaves PIX em andamento...`);
                            typeof attrs.success === 'function' && attrs.success(response.data.data);

                        },
                        function (e) {
                            console.error(e);
                            toastrFactory.error(`Erro solicitando atualização de Chaves PIX...`);
                            typeof attrs.error === 'function' && attrs.error(e);
                        }
                    );
            }

            const cep = attrs => {
                attrs = attrs || {};
                attrs.data = attrs.data || {};
                attrs.data.cep = attrs.data.cep || null;

                if (!attrs.data.cep) throw new Error('Invalid parms');

                attrs.data.cep = globalFactory.onlyNumbers(attrs.data.cep);

                if (attrs.data.cep.length !== 8) throw new Error('Invalid parms');

                $http({
                    url: `https://brasilapi.com.br/api/cep/v2/${attrs.data.cep}`,
                    method: 'get'
                })

                    .then(
                        function (response) {
                            (typeof attrs.success === 'function') && attrs.success(response.data);
                        },
                        function (e) {
                            (typeof attrs.error === 'function') && attrs.error(e);
                        }
                    );
            }

            const cnpj = attrs => {
                attrs = attrs || {};
                attrs.data = attrs.data || {};
                attrs.data.cnpj = attrs.data.cnpj || null;

                if (!attrs.data.cnpj) throw new Error('Invalid parms');

                attrs.data.cnpj = globalFactory.onlyNumbers(attrs.data.cnpj);

                if (attrs.data.cnpj.length !== 14) throw new Error('Invalid parms');

                $http({
                    url: `https://brasilapi.com.br/api/cnpj/v1/${attrs.data.cnpj}`,
                    method: 'get'
                })

                    .then(
                        function (response) {
                            (typeof attrs.success === 'function') && attrs.success(response.data);
                        },
                        function (e) {
                            (typeof attrs.error === 'function') && attrs.error(e);
                        }
                    );
            }

            const checkPixStorage = attrs => {
                attrs = attrs || {};

                attrs.data = attrs.data || {};

                if (!attrs.data.key || !attrs.data.valor) {
                    throw new Error('Invalid parms');
                }

                attrs.data.valor = parseInt((attrs.data.valor * 100).toFixed(0));

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/psc?async=true'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            toastrFactory.info(`Pedido de atualização do Pix Storage chave [${attrs.data.key}], valor [${attrs.data.valor}] foi solicitado...`);

                            if (typeof attrs.success === 'function') attrs.success(response.data.data);

                        },
                        function (e) {
                            console.error(e);
                            toastrFactory.error(`Erro solicitando atualização do Pix Storage chave [${attrs.data.key}], valor [${attrs.data.valor}]...`);
                            if (typeof attrs.error === 'function') attrs.error(e);
                        }
                    );
            }

            const addInfluencerToCampanha = attrs => {
                attrs.data = attrs.data || {};

                if (!attrs.data.idCampanha || !attrs.data.idInfluencer) {
                    throw new Error('Informe idCampanha e idInfluencer');
                }

                $http({
                    url: getUrlEndPoint('/api/eeb/v1/add-influencer-to-campanha?async=true'),
                    method: 'post',
                    data: attrs.data,
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                })

                    .then(
                        function (response) {
                            typeof attrs.success === 'function' && attrs.success(response.data.data);
                        },
                        function (e) {
                            console.error(e);

                            typeof attrs.error === 'function' && attrs.error(e);
                        }
                    );
            }

            return {
                generateTemplates: generateTemplates,
                pagarTituloCompra: pagarTituloCompra,
                checkTituloCompra: checkTituloCompra,
                ativarCampanha: ativarCampanha,
                checkPixStorage: checkPixStorage,
                cep: cep,
                cnpj: cnpj,
                refreshCartosPixKeys: refreshCartosPixKeys,
                addInfluencerToCampanha: addInfluencerToCampanha
            };

        });

export default ngModule;
