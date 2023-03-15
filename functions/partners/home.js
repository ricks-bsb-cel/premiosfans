"use strict";

const path = require('path');
const global = require('../global');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');

exports.get = (request, response) => {

    const types = ['parceiro', 'influencer'];

    const
        version = global.getVersionId(),
        versionDate = global.getVersionDate();
    let
        type = request.query.type || 'parceiro';

    if (!types.includes(type)) type = types[0];

    const render = {
        version: version,
        versionDate: versionDate,
        type: type
    };

    render.config = JSON.stringify(render);

    return response.render(hbsFile, render);
}
