"use strict";

// const admin = require("firebase-admin");
const global = require('../global');
const users = require('../api/users/users');
const secret = require('../secretManager');

exports.getPermissions = (user, request) => {

    return new Promise(resolve => {

        const version = global.getVersionId();
        const host = global.getHost(request);

        let result = {
            redirect: '/adm/unauthorized',
            dalAdmInterface: 'empresaDefault',
            user: user,
            _config: {
                v: version
            },
        };

        if (!user || !user.uid) {
            result = { redirect: '/adm/login' };

            global.config.get('/appProfile/default')

                .then(appProfile => {
                    result.appProfile = appProfile || {};
                    return global.config.get('/appProfile/' + host);
                })

                .then(appProfile => {
                    appProfile = appProfile || {};

                    result.appProfile = { ...result.appProfile, appProfile };

                    return secret.get("premios-fans-firebase-init");
                })
                .then(firebaseInit => {
                    result.firebaseInit = JSON.stringify(firebaseInit);
                    result.firebaseInit = global.toBase64(result.firebaseInit);

                    return resolve(result);
                })

                .catch(e => {
                    console.error(e);
                    result.error = e;
                    return resolve(result);
                })

            return;
        }

        users.getUserProfile(user.uid)

            .then(user => {

                result = Object.assign(result, user);

                result._config.u = result.user.uid;
                result._config.e = result.user.idEmpresa;

                if (result.user.superUser) {
                    result.redirect = '/adm/home';
                    result.dalAdmInterface = 'adm';
                } else {

                    if (result.user.idEmpresa || result.user.superUser) {
                        result.redirect = '/adm/home';
                        result.dalAdmInterface = 'empresaDefault';
                    } else {
                        result.error = "Usuário não vinculado a nenhuma empresa...";
                        return resolve(result);
                    };
                }

                return global.config.get('/appProfile/default');
            })

            .then(appProfile => {

                result.appProfile = appProfile || {};

                return global.config.get('/appProfile/' + host);
            })

            .then(appProfile => {
                result.appProfile = Object.assign(result.appProfile, appProfile || {});

                return secret.get("premios-fans-firebase-init");
            })

            .then(firebaseInit => {
                console.info('***', firebaseInit);

                return resolve(result);
            })

            .catch(e => {
                console.error('getPermissions', e, result);
                result.error = e;
                return resolve(result);
            })

    })

}