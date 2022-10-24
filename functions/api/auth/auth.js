'use strict';

const global = require('../../global');
const admin = require("firebase-admin");
const secret = require('../../secretManager');
const users = require('../users/users');
var url = require('url')

/* https://github.com/auth0/node-jsonwebtoken */
const jwt = require('jsonwebtoken');


exports.requestCreateToken = (request, response) => {

    var apikey = request.query.key || null;
    var uid = request.query.uid || null;

    var user;

    if ((!apikey || !uid) && request.headers['x-envoy-original-path']) {
        var url_parts = url.parse(request.headers['x-envoy-original-path'], true);
        apikey = apikey || url_parts.query.key || null;
        uid = uid || url_parts.query.uid || null;
    }

    if (!apikey || !uid) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'missing apikey or uid'
        }));
    }

    return admin.database().ref(`/apikey/${uid}`).once('value')
        .then(data => {

            data = data.val();

            if (!data || data.apikey !== apikey) {
                throw new Error('invalid uid or apikey');
            }

            return admin.auth().getUser(uid);
        })

        .then(userResult => {

            user = userResult;

            return secret.get('api-default-certificate');
        })

        .then(certificate => {

            var payload = {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                idEmpresa: (user.customClaims || {}).idEmpresa || null
            };

            if ((user.customClaims || {}).superUser) {
                payload.superUser = true;
            }

            payload = Object.assign(payload, user.customClaims);

            var token = jwt.sign(payload, certificate.private_key,
                {
                    algorithm: 'RS256',
                    expiresIn: '1h',
                    audience: certificate.client_id,
                    issuer: certificate.client_email,
                    subject: certificate.client_email
                }
            );

            var result = {
                token: token,
                apikey: apikey,
                uid: uid
                // headers: request.headers
            };

            result = Object.assign(result, payload);

            return response.json(
                global.defaultResult({
                    data: result
                }, true)
            );


        })
        .catch(e => {
            return response.status(500).json(
                global.defaultResult({
                    code: e.code || 500,
                    error: e.message
                })
            );
        })


};


exports.requestCreateCartosToken = (request, response) => {

    const token = global.getUserTokenFromRequest(request, response);

    if (!token) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'empty token'
        }));
    }

    return createCartosToken(token)
        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: result
                }, true)
            );
        })
        .catch(e => {
            console.error(e);
            return response.status(500).json(
                global.defaultResult({
                    code: e.code || 500,
                    error: e.message
                })
            );
        })


}

// Criação do token de acesso à api Zoepay Cartos
// zoepay-cartos-23omfjj7imnmb.apigateway.zoepaygateway.cloud.goog
const createCartosToken = userToken => {
    return new Promise((resolve, reject) => {

        let Usuario = null;

        console.info('createCartosToken', userToken);

        return users.getUserInfoWithToken(userToken)

            .then(user => {

                Usuario = user.data;

                if (!Usuario.idEmpresa) {
                    throw new Error('O usuário atual não está vinculado a uma empresa')
                }

                return secret.get('api-cartos-certificate');
            })

            .then(certificate => {

                console.info('createCartosToken', certificate);

                var payload = {
                    uid: Usuario.uid,
                    idEmpresa: Usuario.idEmpresa
                };

                var token = jwt.sign(payload, certificate.private_key,
                    {
                        algorithm: 'RS256',
                        expiresIn: '1h',
                        audience: certificate.client_id,
                        issuer: certificate.client_email,
                        subject: certificate.client_email
                    }
                );

                payload.data = token;

                return resolve(payload);
            })

            .catch(e => {
                console.error('createCartosToken', e);
                return reject(e);
            })

    })
};

exports.createCartosToken = createCartosToken;
