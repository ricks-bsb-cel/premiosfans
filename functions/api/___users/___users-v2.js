"use strict";

const admin = require("firebase-admin");
const { Timestamp } = require('firebase-admin/firestore');
const global = require('../../global');

const { getAuth } = require("firebase-admin/auth");

const isAdminUser = obj => {
    if (obj && obj.adminUser) return true;
    if (obj && obj.customClaims && obj.customClaims.adminUser) return true;
    return false;
}

const isSuperUser = obj => {
    if (obj && obj.superUser) return true;
    if (obj && obj.customClaims && obj.customClaims.superUser) return true;
    return false;
}


const getUsers = (currentUserToken) => {
    return new Promise((resolve, reject) => {

        return admin.auth().verifyIdToken(currentUserToken)
            .then(userTokenData => {

                if (!isAdminUser(userTokenData) && !isSuperUser(userTokenData))
                    throw new Error(`Apenas usuários administrativos e super usuários podem listar usuários`);

                return getAuth().getUsers([
                ]);

            })

            .then(getUsersResult => {
                console.info(getUsersResult);
                
                return resolve(getUsersResult.users);
            })

            .catch(e => {
                if (e.code === 'auth/id-token-expired') {
                    return reject(new Error(`token expired`));
                } else {
                    return reject(e);
                }
            })

    })
}






exports.requestGetUsers = (request, response) => {
    const token = global.getUserTokenFromRequest(request, response);

    if (!token) return response.status(500).json(
        global.defaultResult({ code: 500, error: 'empty token' })
    );

    getUsers(token)
        .then(result => {
            console.info(result);

            return response.status(200).json(
                global.defaultResult({ data: result }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({ code: e.code || 500, error: e.message })
            );
        })
}