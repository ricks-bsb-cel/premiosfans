"use strict";

const path = require('path');
const Joi = require('joi');
const global = require('../../../global');
const secretManager = require('../../../secretManager');
const eebHelper = require('../../eventBusServiceHelper');
const eebService = require('../../eventBusService').abstract;


const getEndpointConfig = endPoint => {
    return new Promise((resolve, reject) => {

        const result = {};

        return secretManager.get('cartos-api-config')

            .then(secretManagerResult => {
                cartosConfig = secretManagerResult;

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

const login = (cpf, password) => {
    return new Promise((resolve, reject) => {
        return getEndpointConfig('/users/v1/login')
            .then(config => {

                const payload = {
                    username: cpf,
                    password: password,
                    migrate: false
                };

                return eebHelper.http.post(
                    config.endPoint,
                    payload,
                    config.headers
                );

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



exports.login = login;