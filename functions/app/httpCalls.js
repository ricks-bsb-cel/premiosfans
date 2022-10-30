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

app.get('/', (request, response) => {
    initFirebase.call(require('./home').get, request, response);
});

exports.mainApp = app;
