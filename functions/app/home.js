"use strict";

const admin = require('firebase-admin');
const global = require('../global');
const path = require('path');
const fs = require('fs');

const bucketName = 'premios-fans.appspot.com';

const fakeData = {
    influencer: {
        nomeExibicao: "João da Silva"
    },
    campanha: {
        imagePrincipal: "https://res.cloudinary.com/dckw5m2ep/image/upload/v1667436396/premiosfans/jyhkd0e8zh3jythunvzs.jpg",
        titulo: "Campanha de Natal 2025",
        subTitulo: "Seu Natal cheio de Grana no Bolso!",
        detalhes: "No entanto, não podemos esquecer que o novo modelo estruturalista aqui preconizado auxilia a preparação e a composição das posturas dos filósofos divergentes com relação às atribuições conceituais. Do mesmo modo, a indeterminação contínua de distintas formas de fenômeno garante a contribuição de um grupo importante na determinação das novas teorias propostas. Deste modo, acabei de refutar a tese segundo a qual a consolidação das estruturas psico-lógicas assume importantes posições no estabelecimento dos conhecimentos a priori."
    },
    config: {
        qtdMaximaCompraSugerida: 6,
        qtdMaximaCompra: 12,
        vlTitulo: 5
    }

}


exports.getApp = (request, response) => {
    const idInfluencer = request.params.idInfluencer || null;
    const idCampanha = request.params.idCampanha || null;

    const storageFile = `app/${idInfluencer}/${idCampanha}/index.html`;

    const bucket = admin.storage().bucket(bucketName);
    const file = bucket.file(storageFile);

    const render = {
        storageFile: storageFile
    };

    return file.getMetadata()
        .then(getMetadataResponse => {
            render.metadata = getMetadataResponse;
            render.size = getMetadataResponse[0].size;
            render.contentType = getMetadataResponse[0].contentType;

            const metadata = {
                contentType: render.contentType,
                cacheControl: 'public, max-age=0',
                connection: 'keep-alive',
                contentLength: render.size
            };

            response.setHeader('content-type', metadata.contentType);
            response.setHeader('cache-control', metadata.cacheControl);
            response.setHeader('connection', metadata.connection);
            response.setHeader('content-length', metadata.contentLength);

            return file
                .createReadStream(
                    { resumable: false, metadata: metadata }
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

exports.getTemplate = (request, response) => {
    const nome = request.params.nome;
    const templateFile = path.join(__dirname, '../storage/templates', nome, 'index.html');
    const host = global.getHost(request);

    if (!host === 'localhost') return response.redirect('/');

    response.setHeader('content-type', 'text/html; charset=utf-8');
    response.setHeader('cache-control', 'public, max-age=0');
    response.setHeader('connection', 'keep-alive')

    const render = { ...fakeData };

    render.config.sugestoes = [];

    for (let i = 1; i <= render.config.qtdMaximaCompraSugerida; i++) {
        render.config.sugestoes.push({
            qtd: i,
            qtdExibicao: `${i} Título${i > 1 ? 's' : ''}`,
            vlTotal: render.config.vlTitulo * i,
            vlTotalExibicao: `<strong>R$ ${render.config.vlTitulo * i}</strong><small>,00</small>`
        })
    }

    try {
        const template = fs.readFileSync(templateFile).toString();
        const compiled = global.compile(template, render);

        return response.status(200).send(compiled);
    }
    catch (e) {
        render.error = e.toString();
        console.error(e);
        return response.status(500).json(render);
    }
}


exports.getStorageFile = (request, response) => {

    const render = {
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
    if (request.params && request.params[name]) {
        return '/' + request.params[name];
    } else {
        return '';
    }
}
