'use strict';

const ngModule = angular.module('services.utilsService', [])

    .factory('utilsService',
        function (
            globalFactory,
            appAuthHelper,
            $http,
            URLs,
            waitUiFactory
        ) {

            const getCep = attrs => {

                if (!attrs.cep) {
                    throw new Error('Parm error...');
                }

                attrs.cep = globalFactory.onlyNumbers(attrs.cep);

                waitUiFactory.start();

                $http({
                    url: URLs.utils.getCep + '/' + attrs.cep,
                    method: 'get'
                }).then(
                    function (response) {
                        waitUiFactory.stop();
                        if (typeof attrs.success == 'function') {
                            attrs.success(response.data.data);
                        }
                    },
                    function (e) {
                        waitUiFactory.stop();
                        if (typeof attrs.error == 'function') {
                            console.error(e);
                            attrs.error(e);
                        }
                    }
                );

            }

            return {
                getCep: getCep
            };

        });

export default ngModule;
