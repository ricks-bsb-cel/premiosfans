'use strict';

const ngModule = angular.module('services.utilsService', [])

    .factory('utilsService',
        function (
            globalFactory,
            appAuthHelper,
            $http,
            URLs,
            blockUiFactory,
            toastrFactory
        ) {

            const getCep = attrs => {

                if (!attrs.cep) {
                    throw new Error('Parm error...');
                }

                attrs.cep = globalFactory.onlyNumbers(attrs.cep);

                blockUiFactory.start();

                $http({
                    url: URLs.utils.cep + '/' + attrs.cep,
                    method: 'get',
                    headers: {
                        'Authorization': 'Bearer ' + appAuthHelper.token
                    }
                }).then(
                    function (response) {
                        blockUiFactory.stop();
                        if (typeof attrs.success === 'function') {
                            attrs.success(response.data.data);
                        }
                    },
                    function (e) {
                        blockUiFactory.stop();
                        toastrFactory.info('CEP não localizado...');
                        if (typeof attrs.error === 'function') {
                            console.error(e);
                            attrs.error(e);
                        }
                    }
                );

            }

            const minifyHtml = attrs => {

                return new Promise((resolve, reject) => {

                    if (!attrs.html) {
                        return reject(new Error('Parm error...'));
                    }

                    $http({
                        url: 'https://www.toptal.com/developers/html-minifier/api/raw',
                        method: 'post',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                        },
                        data: attrs.html
                    }).then(
                        function (response) {
                            return resolve(response.data);
                        },
                        function (e) {
                            return reject(e);
                        }
                    );

                })

            }

            return {
                getCep: getCep,
                minifyHtml: minifyHtml
            };

        });

export default ngModule;
