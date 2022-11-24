'use strict';

const ngModule = angular.module('services.premios-fans', [])

    .factory('premiosFansService',
        function (
            appAuthHelper,
            $http,
            blockUiFactory,
            toastrFactory
        ) {

            const getUrlEndPoint = url => {
                const localUrl = 'http://localhost:5000';
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

            return {
                generateTemplates: generateTemplates,
                pagarTituloCompra: pagarTituloCompra
            };

        });

export default ngModule;
