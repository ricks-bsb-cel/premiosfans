"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');
// const users = require('../api/users/users');

const updateUserProfile = require('../eeb/services/users/updateUserProfile');
const helper = require('../eeb/eventBusServiceHelper');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');
const hbsPartials = path.join(hbsPath, '/partials/home');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    helper.getUserTokenFromRequest(request, response)

    return updateUserProfile.updateWithToken(request, response)

        .then(updateUserProfileResult => {
            return adminController.getPermissions(updateUserProfileResult);
        })

        .then(result => {
            if (result.redirect === '/adm/home') {
                console.info('render', JSON.stringify(result));
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
