"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');
const users = require('../api/users/users');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, 'login.hbs');
const hbsPartials = path.join(hbsPath, 'partials/login');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    const clearLogin = Object.keys(request.query).includes('clear');

    return users.checkUserProfile(request, response)

        .then(user => {
            return adminController.getPermissions(user, request);
        })

        .then(result => {
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