"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');
const users = require('../api/users/users');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = hbsPath + '/login.hbs';
const hbsPartials = hbsPath + '/partials/login';

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    const clearLogin = Object.keys(request.query).includes('clear');

    users.getCurrentUserFromCookie(request, response)

        .then(user => {
            return adminController.getPermissions(user, request);
        })

        .then(result => {
            if (clearLogin || result.redirect === '/adm/login') {
                return response.render(hbsFile, response.data);
            } else {
                return response.redirect(result.redirect);
            }
        })

        .catch(e => {
            console.error(e);
            return response.send(e);
        })

}