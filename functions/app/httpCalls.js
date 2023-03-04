'use strict';

const express = require('express');
const engines = require('consolidate');
const minifyHTML = require('express-minify-html');

const initFirebase = require('../initFirebase');

const handlebarsRegisterHelpers = require('../handlebarsRegisterHelpers');

handlebarsRegisterHelpers.run();

const app = express();

app.use(minifyHTML({
    override: true,
    exception_url: false,
    htmlMinifier: {
        removeComments: true,
        collapseWhitespace: true,
        collapseBooleanAttributes: true,
        removeAttributeQuotes: true,
        removeEmptyAttributes: true,
        minifyJS: true
    }
}));

app.engine('hbs', engines.handlebars);
app.set('view engine', 'hbs');

app.get('/app/:idInfluencer/:idCampanha', (request, response) => {
    initFirebase.call(require('./home').getApp, request, response);
});

/*
app.get('/template/:nome', (request, response) => {
    initFirebase.call(require('./home').getTemplate, request, response);
});
*/

// Busca por Template
// Template main, que está em functions/storage/templates/main
// Todo HTML do template fica em index.html
/*
app.get('/', (request, response) => {
    request.params.dirFile1 = 'templates';
    request.params.dirFile2 = 'main';
    request.params.dirFile3 = 'index.html';

    initFirebase.call(require('./home').getStorageFile, request, response);
});
*/

app.get('/:dirFile1/:dirFile2?/:dirFile3?/:dirFile4?/:dirFile5?', (request, response) => {
    initFirebase.call(require('./home').getStorageFile, request, response);
});

app.get('/', (request, response) => {
    return response.json({ root: 'root' }).end();
})

exports.mainApp = app;
