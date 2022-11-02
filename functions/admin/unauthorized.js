"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');

const users = require('../api/users/users');
const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/unauthorized.hbs');
const hbsPartials = path.join(hbsPath, '/partials/unauthorized');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    users.getCurrentUserFromCookie(request, response)

        .then(user => {
            return adminController.getPermissions(user, request);
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
