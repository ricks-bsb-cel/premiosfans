"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');

const updateUserProfile = require('../eeb/services/usersUpdateUserProfile');
const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/unauthorized.hbs');
const hbsPartials = path.join(hbsPath, '/partials/unauthorized');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    return updateUserProfile.updateWithToken(request, response)

        .then(updateUserProfileResult => {
            return adminController.getPermissions(updateUserProfileResult);
        })

        .then(result => {
            if (result.redirect === '/adm/unauthorized') {
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
