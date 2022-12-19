"use strict";

const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');

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

async function callPost(url, payload, headers) {
    const config = await getEndpointConfig(url);

    if (headers) {
        config.headers = {
            ...config.headers,
            ...headers
        };
    }

    const requestResult = await eebHelper.http.post(config.endPoint, payload, config.headers);

    if (requestResult.statusCode !== 200) {
        console.error('cartosHttpRequest.callPost', config, payload, requestResult);
        throw new Error(JSON.stringify(requestResult));
    }

    return requestResult.data;
}

async function callGet(url, headers) {
    const config = await getEndpointConfig(url);

    if (headers) {
        config.headers = {
            ...config.headers,
            ...headers
        };
    }

    const requestResult = await eebHelper.http.get(config.endPoint, config.headers);

    if (requestResult.statusCode !== 200) {
        console.error('cartosHttpRequest.callGet', config, requestResult);
        throw new Error(JSON.stringify(requestResult));
    }

    return requestResult.data;
}

const login = (cpf, password) => {
    const parm = {
        username: cpf,
        password: password,
        migrate: false
    };

    return callPost('/users/v1/login', parm);
}

const changeAccount = (accountId, token) => {
    const
        parm = { accountId: accountId },
        headers = { Authorization: `Bearer ${token}` };

    return callPost('/users/v1/login/change-account', parm, headers);
}

const accounts = token => {
    const headers = {
        Authorization: `Bearer ${token}`
    };

    return callGet('/digital-account/v1/accounts?typeRequest=byCpfHash', headers);
}

const balance = (token) => {
    const headers = { Authorization: `Bearer ${token}` };

    return callGet('/account-digital/v1/balance', headers);
}

const extract = (token) => {
    const headers = { Authorization: `Bearer ${token}` };

    return callGet('/account-digital/v1/extract', headers);
}

const pixKeys = (token) => {
    const headers = { Authorization: `Bearer ${token}` };

    return callGet('/digital-account/v1/pix-keys', headers);
}

const generatePix = (data, token) => {
    const headers = { Authorization: `Bearer ${token}` };

    const payload = {
        receiverKey: data.receiverKey,
        merchantCity: data.merchantCity,
        additionalInfo: data.additionalInfo
    };

    if (data.value) {
        payload.value = data.value;
    }

    const url = data.type === 'STATIC' ? '/digital-account/v1/pix-static-qrcodes' : '/digital-account/v1/pix-dynamic-qrcodes';

    return callPost(url, payload, headers);
}

exports.login = login;
exports.accounts = accounts;
exports.changeAccount = changeAccount;
exports.balance = balance;
exports.extract = extract;
exports.pixKeys = pixKeys;
exports.generatePix = generatePix;
