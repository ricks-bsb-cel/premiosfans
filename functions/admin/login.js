"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, 'login.hbs');
const hbsPartials = path.join(hbsPath, 'partials/login');

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    const clearLogin = Object.keys(request.query).includes('clear');

    adminController.checkToken(request, response)
        .then(checkTokenResult => {
            if (clearLogin || checkTokenResult.redirect === '/adm/login') {
                return response.render(hbsFile, checkTokenResult);
            } else {
                return response.redirect(checkTokenResult.redirect)
            }
        })
        .catch(e => {
            console.error(e);

            return response.send(e);
        })

}
