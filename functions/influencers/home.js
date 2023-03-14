"use strict";

const path = require('path');
const global = require('../global');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');

exports.get = (request, response) => {
    const render = {
        version: global.getVersionId(),
        versionDate: global.getVersionDate()
    }

    return response.render(hbsFile, render);
}
