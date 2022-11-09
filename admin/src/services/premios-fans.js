'use strict';

const ngModule = angular.module('services.premios-fans', [])

    .factory('premiosFansService',
        function (
            appAuthHelper,
            $http,
            blockUiFactory,
            toastrFactory
        ) {

            const generateTemplates = attrs => {
                attrs = attrs || {
                    blockUi: true
                };
                attrs.data = attrs.data || {};

                attrs.data.idInfluencer = attrs.data.idInfluencer || 'all';
                attrs.data.idCampanha = attrs.data.idCampanha || 'all';

                if (attrs.blockUi) blockUiFactory.start();

                $http({
                    url: 'https://premios-fans-a8fj1dkb.uc.gateway.dev/api/eeb/v1/generate-templates',
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

            return {
                generateTemplates: generateTemplates
            };

        });

export default ngModule;
