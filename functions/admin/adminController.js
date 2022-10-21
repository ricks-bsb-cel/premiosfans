/* eslint-disable consistent-return */
"use strict";

// const admin = require("firebase-admin");
const global = require('../global');
const users = require('../api/users/users');

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
                    result.appProfile = Object.assign(result.appProfile, appProfile || {});

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
                    }
                }

                return global.config.get('/appProfile/default');
            })

            .then(appProfile => {

                result.appProfile = appProfile || {};

                return global.config.get('/appProfile/' + host);
            })

            .then(appProfile => {
                result.appProfile = Object.assign(result.appProfile, appProfile || {});

                return resolve(result);
            })

            .catch(e => {
                console.error('getPermissions', e, result);
                result.error = e;
                return resolve(result);
            })

    })
}

/*
const getEmpresas = (user) => {
    return new Promise((resolve, reject) => {

        var query = dalEmpresas.collection;
        var empresas = [];

        console.info(user);

        if (!user.superUser) {
            if (user.idEmpresas.length) {
                query = query
                    .where(admin.firestore.FieldPath.documentId(), 'in', (user.idEmpresas || []))
                    .where('ativa', '==', true);
            } else {
                return reject(new Error('Usuário sem nenhuma empresa vinculada'));
            }
        }

        query
            .get()
            .then(docs => {
                docs.forEach(d => {
                    empresas.push(Object.assign(d.data(), { id: d.id }));
                })
                return dalUserProfile.getDoc(user.uid);
            })
            .then(userProfile => {
                var i = empresas.findIndex(f => { return f.id === userProfile.idEmpresaAtual; });
                if (i >= 0) {
                    empresas[i].selected = true;
                } else {
                    console.error('Profile error', userProfile);
                }
                return resolve(empresas);
            })
            .catch(e => {
                console.error(e);
                return reject(e);
            })

    });
}
*/

/*
// Substitui o getPermissions
exports.getPerfil = user => {
    return new Promise(resolve => {

        var result = {
            user: {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName || null,
                photoURL: user.photoURL || null,
                phoneNumber: user.phoneNumber || null,
                superUser: user.superUser
            }
        }

        // Verifica se não é superusuario
        dalSuperUser.getDoc(user.uid, false)
            .then(resultSuperUser => {

                throw new Error('Not implemented...');

                if (resultSuperUser) {

                } else {

                }

            })

            .then(result => {
                return resolve(result);
            })

            .catch(e => {
                result.error = e;
                return reject(result);
            })

    })
}
*/