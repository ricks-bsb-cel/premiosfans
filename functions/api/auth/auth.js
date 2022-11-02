'use strict';

const global = require('../../global');
const admin = require("firebase-admin");
const secret = require('../../secretManager');
const url = require('url')

/* https://github.com/auth0/node-jsonwebtoken */
const jwt = require('jsonwebtoken');

exports.requestCreateToken = (request, response) => {

    let apikey = request.query.key || null,
        uid = request.query.uid || null,
        user;

    if ((!apikey || !uid) && request.headers['x-envoy-original-path']) {
        const url_parts = url.parse(request.headers['x-envoy-original-path'], true);
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

            let payload = {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                idEmpresa: (user.customClaims || {}).idEmpresa || null
            };

            if ((user.customClaims || {}).superUser) {
                payload.superUser = true;
            }

            payload = Object.assign(payload, user.customClaims);

            const token = jwt.sign(payload, certificate.private_key,
                {
                    algorithm: 'RS256',
                    expiresIn: '1h',
                    audience: certificate.client_id,
                    issuer: certificate.client_email,
                    subject: certificate.client_email
                }
            );

            let result = {
                token: token,
                apikey: apikey,
                uid: uid
            };

            result = Object.assign(result, payload);

            return response.json(
                global.defaultResult({ data: result }, true)
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
