"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');

const updateUserProfile = require('../eeb/services/users/updateUserProfile');
const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, 'login.hbs');
const hbsPartials = path.join(hbsPath, 'partials/login');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    const clearLogin = Object.keys(request.query).includes('clear');

    return updateUserProfile.updateWithToken(request, response)

        .then(updateUserProfileResult => {
            return adminController.getPermissions(updateUserProfileResult);
        })

        .then(result => {
            console.info('login', result.redirect);
            if (clearLogin || result.redirect === '/adm/login') {
                return response.render(hbsFile, result);
            } else {
                return response.redirect(result.redirect);
            }
        })

        .catch(e => {
            console.error(e);
            return response.send(e);
        })

}
