"use strict";

const global = require('../../global');

const users = require('./users');

exports.requestMergeUserProfileWithUserData = (request, response) => {

    const uid = request.params.uid || null;

    if (!uid) {
        return response.status(500).json(
            global.defaultResult({ code: 500, error: 'uid not found' }, true)
        );
    }

    return users.mergeUserProfileWithUserData(uid)

        .then(result => {
            return response.status(200).json(
                global.defaultResult(result, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({ code: e.code, error: e.message }, true)
            );
        })

};


exports.requestAllMergeUserProfileWithUserData = (request, response) => {

    return users.mergeAllUserProfileWithUserData()

        .then(result => {
            return response.status(200).json(
                global.defaultResult(result, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({ code: e.code, error: e.message }, true)
            );
        })

};

