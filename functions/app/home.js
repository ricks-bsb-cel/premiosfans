"use strict";

const admin = require('firebase-admin');
const global = require('../global');
const path = require('path');
const _ = require("lodash");
const fs = require('fs');

const minify = require('html-minifier').minify;
const UglifyJS = require("uglify-js");
const CleanCSS = require('clean-css');

const bucketName = 'premios-fans.appspot.com';

const GoogleCloudStorage = require('../api/googleCloudStorage');
const templateBucket = "premios-fans-templates";
const templateBucketPath = "storage/templates";
const templateStorage = new GoogleCloudStorage(templateBucket, templateBucketPath);

const defaultTemplateConfig = {
    qtdMaximaCompraSugerida: 6,
    qtdMaximaCompra: 12,
    vlTitulo: 5,
    sugestoes: []
};

const fakeData = {
    version: global.generateRandomId(7),
    influencer: {
        nomeExibicao: "João da Silva"
    },
    campanha: {
        imagePrincipal: "https://res.cloudinary.com/dckw5m2ep/image/upload/v1667942171/premiosfans/zg1fdq9nyc1otnkuwwlv.png",
        titulo: "Campanha de Natal 2025",
        subTitulo: "Seu Natal cheio de Grana no Bolso!",
        detalhes: "No entanto, não podemos esquecer que o novo modelo estruturalista aqui preconizado auxilia a preparação e a composição das posturas dos filósofos divergentes com relação às atribuições conceituais. Do mesmo modo, a indeterminação contínua de distintas formas de fenômeno garante a contribuição de um grupo importante na determinação das novas teorias propostas. Deste modo, acabei de refutar a tese segundo a qual a consolidação das estruturas psico-lógicas assume importantes posições no estabelecimento dos conhecimentos a priori.",
        images: [
            {
                secure_url: "https://res.cloudinary.com/dckw5m2ep/image/upload/v1667942171/premiosfans/zg1fdq9nyc1otnkuwwlv.png"
            }
        ],
        premios: [
            {
                qtd: 2,
                descricao: "PIX de R$ 10.000 Reais",
                valor: 10000,
                dtSorteio: "25/12/2022"
            },
            {
                qtd: 2,
                descricao: "PIX de 10.000 Reais",
                valor: 10000,
                dtSorteio: "25/12/2022"
            },
            {
                qtd: 1,
                descricao: "GM Tracker GLSI 2022 Zero!",
                valor: 150000,
                dtSorteio: "25/12/2022"
            },
            {
                qtd: 1,
                descricao: "BMW GLSI 2022 Zero!",
                valor: 200000,
                dtSorteio: "31/12/2022"
            },
            {
                qtd: 2,
                descricao: "PIX de 10.000 Reais",
                valor: 10000,
                dtSorteio: "31/12/2022"
            },
            {
                qtd: 2,
                descricao: "PIX de 100.000 Reais",
                valor: 100000,
                dtSorteio: "05/01/2023"
            }
        ]
    },
    config: defaultTemplateConfig
}

// Este sempre vai retornar o index.html
exports.getWithUrl = (request, response) => {
    const url = request.params.url;
    const debug = request.query && request.query.debug === 'true';
    const type = debug ? 'debug' : 'min';

    let dirFile2 = getParam(request, 'dirFile2');

    const dirFile3 = getParam(request, 'dirFile3'),
        dirFile4 = getParam(request, 'dirFile4'),
        dirFile5 = getParam(request, 'dirFile5');

    if (!dirFile2 && !dirFile3 && !dirFile4 && !dirFile5) dirFile2 = 'index.html';

    // Localiza a URL no RTDB
    return admin.database().ref(`/urlCampanha/${url}`).once("value")
        .then(urlData => {

            if (!urlData.exists()) {
                return response.status(404).json({
                    success: false,
                    url: url,
                    error: 'not found'
                })
            }

            urlData = urlData.val();

            let file = `templates/${urlData.idTemplate}/${urlData.idCampanha}/${urlData.idInfluencer}/${type}`;

            if (dirFile2) file += '/' + dirFile2;
            if (dirFile3) file += '/' + dirFile3;
            if (dirFile4) file += '/' + dirFile4;
            if (dirFile5) file += '/' + dirFile5;

            return templateStorage.responseFile(response, file);
        })
        .catch(e => {
            return response.status(500).json({
                success: false,
                url: url,
                error: JSON.stringify(e)
            })
        })
}

exports.getTemplateFile = (request, response) => {
    const
        dirFile1 = getParam(request, 'dirFile1'),
        dirFile2 = getParam(request, 'dirFile2'),
        dirFile3 = getParam(request, 'dirFile3'),
        dirFile4 = getParam(request, 'dirFile4'),
        dirFile5 = getParam(request, 'dirFile5');

    let file = `templates`;

    if (dirFile1) file += dirFile1;
    if (dirFile2) file += dirFile2;
    if (dirFile3) file += dirFile3;
    if (dirFile4) file += dirFile4;
    if (dirFile5) file += dirFile5;

    return templateStorage.responseFile(response, file);
}

exports.getApp = (request, response) => {
    const idInfluencer = request.params.idInfluencer || null;
    const idCampanha = request.params.idCampanha || null;

    const storageFile = `app/${idInfluencer}/${idCampanha}/index.html`;

    const bucket = admin.storage().bucket(bucketName);
    const file = bucket.file(storageFile);

    const render = { storageFile: storageFile };

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

    fs.readFile(templateFile, (e, template) => {

        if (e) {
            console.error(e);

            return response.status(500).json({
                error: e.toString()
            });
        }

        return compileApp(template, fakeData)

            .then(compiled => {
                return response.status(200).send(compiled);
            })

            .catch(e => {
                console.error(e);
                return response.status(500).json({
                    error: e.toString()
                });
            })
    })
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

// passar para async
async function compileApp(sourceData, obj, minifyExtension) {
    const render = { ...obj };

    try {
        render.config = render.config || defaultTemplateConfig;
        render.config.sugestoes = [];

        if (render.campanha.images && render.campanha.images.length) {
            render.campanha.imagePrincipal = render.campanha.images[0].secure_url;
        } else {
            render.campanha.imagePrincipal = fakeData.campanha.images[0].secure_url
        }

        render.campanha.thumb = render.campanha.imagePrincipal.replace('/upload/', '/upload/c_thumb,h_500,w_500/');

        for (let i = 1; i <= 6; i++) {
            render.config.sugestoes.push({
                id: global.generateRandomId(7),
                qtd: i,
                qtdExibicao: `<strong>${i}</strong> <small>Título${i > 1 ? 's' : ''}</small>`,
                vlTotal: render.campanha.vlTitulo * i,
                vlTotal_html: global.formatMoney(render.campanha.vlTitulo * i, true, true),
                chances: parseInt((render.campanha.qtdPremios * i).toFixed(0))
            })
        }

        render.campanhaSorteios = render.campanhaSorteios.map((s, i) => {

            s.premios = render.campanhasSorteiosPremios
                .filter(f => {
                    return f.idSorteio === s.id;
                })
                .map(p => {
                    p.valor_html = global.formatMoney(p.valor, true, true);

                    return p;
                })

            s.titulo = (i + 1) + 'º Sorteio';
            s.titulo_html = `<strong>${i + 1}º</strong> <small>Sorteio</small>`;
            s.vlTotalPremios_html = global.formatMoney(s.vlTotalPremios, true, true);

            s.premios = _.orderBy(s.premios, ['pos']);

            return s;
        })

        render.campanhasSorteios = _.orderBy(render.campanhasSorteios, ['dtSorteio_yyyymmdd']);

        render.campanha.description =
            render.campanha.detalhes ||
            render.campanha.subTitulo ||
            render.campanha.titulo;

        let compiled = global.compile(sourceData, render);

        // Substitui os marcadores do AngularJS (que foram criados com [[ e ]] e não {{ e }}
        compiled = compiled.split('[[').join('{{');
        compiled = compiled.split(']]').join('}}');

        switch (minifyExtension) {
            case ".html":
                compiled = minify(compiled, {
                    collapseWhitespace: true,
                    removeComments: true,
                    preserveLineBreaks: false
                });

                break;
            case ".js":
                compiled = UglifyJS.minify(compiled, {
                    mangle: false,
                }).code;

                break;
            case ".css":
                compiled = new CleanCSS().minify(compiled).styles;

                break;
            default:
                break;
        }

        return compiled;
    } catch (e) {
        console.error(e);

        throw new Error(e);
    }
}

exports.defaultTemplateConfig = defaultTemplateConfig;
exports.compileApp = compileApp;
