"use strict";

const admin = require('firebase-admin');
const global = require('../../global');

const firestoreDAL = require('../firestoreDAL');

const appUsers = firestoreDAL.appUsers();

const userProfileReference = uid => {
    return admin.database().ref(`/app/${uid}/profile`);
}

const getAppUser = (uid, notFoundError) => {

    if (!uid) {
        throw global.newError('Requisição inválida');
    }

    notFoundError = typeof notFoundError === 'boolean' ? notFoundError : true;

    return new Promise((resolve, reject) => {

        return userProfileReference(uid).once("value")

            .then(result => {
                result = result.val() || null;

                if (notFoundError && !result) {
                    throw global.newError('Perfil do usuário não existe no provedor financeiro')
                }

                return resolve(result);
            })

            .catch(e => {
                console.error(e);
                return reject(e);
            })
    })
}

const setAppUser = (uid, profileData) => {

    if (!uid || !profileData) {
        throw global.newError('Requisição inválida');
    }

    return new Promise((resolve, reject) => {

        userProfileReference(uid)
            .transaction(data => {

                data = data || {};

                if (!data.cpf) { data.cpf = profileData.cpf; }
                if (!data.phoneNumber) { data.phoneNumber = profileData.phoneNumber; }
                if (!data.dtInclusao) { data.dtInclusao = global.getToday() }

                if (profileData.displayName) { data.displayName = profileData.displayName; }
                if (profileData.email) { data.email = profileData.email; }

                if (profileData.dtNascimento) { data.dtNascimento = profileData.dtNascimento; }

                data.dtAtualizacao = global.getToday();

                appUsers.merge(uid, data);

                return data;
            })
            .then(_ => {
                return resolve();
            })
            .catch(e => {
                console.error(e);
                return reject(e);
            })

    })

}

exports.getAppUser = getAppUser;
exports.setAppUser = setAppUser;