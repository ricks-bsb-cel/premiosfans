"use strict";

const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;

const getEndpointConfig = endPoint => {
    return new Promise((resolve, reject) => {
        const result = {};

        return secretManager.get('cartos-api-config')

            .then(secretManagerResult => {
                const cartosConfig = secretManagerResult;

                result.endPoint = cartosConfig.endpoint_url_production + endPoint;

                result.headers = {
                    "x-api-key": cartosConfig.api_key,
                    "device_id": 'void'
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

const callPost = (url, payload) => {
    return new Promise((resolve, reject) => {
        return getEndpointConfig(url)
            .then(config => {
                return eebHelper.http.post(config.endPoint, payload, config.headers);
            })

            .then(requestResult => {
                if (requestResult.statusCode !== 200) {
                    throw new Error(JSON.stringify(requestResult));
                }

                return resolve(requestResult.data);
            })

            .catch(e => {
                return reject(e);
            })
    })
}

const callGet = (url, headers) => {
    return new Promise((resolve, reject) => {
        return getEndpointConfig(url)
            .then(config => {
                if (headers) {
                    config.headers = {
                        ...config.headers,
                        ...headers
                    };
                }

                return eebHelper.http.get(config.endPoint, config.headers);
            })

            .then(requestResult => {
                if (requestResult.statusCode !== 200) {
                    throw new Error(JSON.stringify(requestResult));
                }

                return resolve(requestResult.data);
            })

            .catch(e => {
                return reject(e);
            })
    })
}

const login = (cpf, password) => {
    const parm = {
        username: cpf,
        password: password,
        migrate: false
    };

    return callPost('/users/v1/login', parm);
}

const changeAccount = (accountId) => {
    return callPost('users/v1/login/change-account', {
        accountId: accountId
    })
}

const accounts = token => {
    const headers = {
        Authorization: `Bearer ${token}`
    };

    return callGet('/digital-account/v1/accounts?typeRequest=byCpfHash', headers);
}

exports.login = login;
exports.accounts = accounts;
exports.changeAccount = changeAccount;