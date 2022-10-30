"use strict";

const path = require('path');
const global = require('../global');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');

// const hbsPartials = path.join(hbsPath, '/partials/home');

exports.get = (request, response) => {
    var render = {
        version: global.getVersionId(),
        versionDate: global.getVersionDate()
    }

    return response.render(hbsFile, render);
}
