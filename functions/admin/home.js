"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');
const users = require('../api/users/users');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');
const hbsPartials = path.join(hbsPath, '/partials/home');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    return users.checkUserProfile(request, response)

        .then(user => {
            return adminController.getPermissions(user, request);
        })

        .then(result => {
            if (result.redirect === '/adm/home') {
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
