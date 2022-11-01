"use strict";

const admin = require('firebase-admin');
const path = require('path');
const global = require('../global');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');

const bucketName = 'premios-fans.appspot.com';

exports.getStorageFile = (request, response) => {

    let render = {
        version: global.getVersionId(),
        versionDate: global.getVersionDate(),
        host: global.getHost(request)
    };

    render.storagePath = `storage/${render.host === 'localhost' ? 'dev' : 'prod'}`;

    render.storagePath += getParam(request, 'dirFile1');
    render.storagePath += getParam(request, 'dirFile2');
    render.storagePath += getParam(request, 'dirFile3');
    render.storagePath += getParam(request, 'dirFile4');
    render.storagePath += getParam(request, 'dirFile5');

    if (!render.storagePath) render.storagePath = 'index.html';
    if (render.storagePath.startsWith('/')) render.storagePath = render.storagePath.substring(1);

    const bucket = admin.storage().bucket(bucketName);
    const file = bucket.file(render.storagePath);

    return file.getMetadata()
        .then(metadata => {
            render.metadata = metadata;
            render.size = metadata[0].size;
            render.contentType = metadata[0].contentType;

            response.setHeader('cache-control', 'public, max-age=0');
            response.setHeader('connection', 'keep-alive');
            response.setHeader('content-length', render.size);
            response.setHeader('content-type', `${render.contentType}; charset=utf-8`);

            return file
                .createReadStream(
                    {
                        resumable: false,
                        metadata: {
                            contentType: render.contentType,
                            cacheControl: 'public, max-age=0',
                            connection: 'keep-alive',
                            contentLength: render.size
                        }
                    }
                )
                .on('error', function (e) {
                    return response.status(500).send(e);
                })
                .on('finish', function () {
                    return response.end();
                })
                .pipe(response)

        })

        .catch(e => {
            if (e.code === 404) {
                render.error = 'not found';

                return response.status(404).json(render);
            } else {
                render.error = e;
                console.error(e);
                return response.status(500).json(render);
            }
        })
}

const getParam = (request, name) => {
    if (request.params && request.params[name])
        return '/' + request.params[name];
    else
        return '';
}
