"use strict";

const admin = require("firebase-admin");

const global = require('../global');
const secret = require('../secretManager');
const helper = require('../eeb/eventBusServiceHelper');

exports.getPermissions = user => {
    return new Promise((resolve, reject) => {
        const version = global.getVersionId();

        let result = {
            redirect: '/adm/unauthorized',
            dalAdmInterface: 'empresaDefault',
            user: user,
            _config: {
                v: version
            },
            version: version
        };

        return secret.get("premios-fans-firebase-init")
            .then(firebaseInit => {
                result.firebaseInit = JSON.stringify(firebaseInit);
                result.firebaseInit = global.toBase64(result.firebaseInit);
                result.version = version;

                if (!user || !user.uid) {
                    result = { redirect: '/adm/login' };
                    return resolve(result);
                }

                if (!user.customClaims || !user.customClaims.idConfigProfile) {
                    result.message = `Usuário não configurado para nenhum perfil de acesso`;
                    return resolve(result);
                }

                result._config.u = user.uid;
                result._config.e = user.idEmpresa || null;

                result.user.superUser = user.customClaims.superUser || false;

                result.redirect = '/adm/home';
                result.dalAdmInterface = 'adm';

                /*
                if (result.user.superUser) {
                    result.redirect = '/adm/home';
                    result.dalAdmInterface = 'adm';
                } else {
                    result.redirect = '/adm/unauthorized';
                    result.dalAdmInterface = 'empresaDefault';

                    if (result.user.idEmpresa || result.user.superUser) {
                        result.redirect = '/adm/home';
                        result.dalAdmInterface = 'empresaDefault';
                    } else {
                        result.error = "Usuário não vinculado a nenhuma empresa...";
                    }
                }
                */

                return resolve(result);
            })

            .catch(e => {
                console.error(e);
                result.error = e;

                return reject(result);
            })


    })
}

exports.checkToken = (request, response) => {
    return new Promise(resolve => {
        const token = helper.getUserTokenFromRequest(request, response);

        const version = global.getVersionId();

        const result = {
            redirect: '/adm/login',
            _config: { v: version },
            version: version
        };

        if (!token) {
            return resolve(result)
        }

        return admin.auth().verifyIdToken(token)
            .then(user => {
                if (user.provider_id === 'anonymous') {
                    return resolve(result);
                } else {
                    result.redirect = '/adm/home';
                    return resolve(result);
                }
            })
            .catch(e => {
                console.error(e);
                return resolve(result);
            })
    })
}
