'use strict';

const express = require('express');
const engines = require('consolidate');
const minifyHTML = require('express-minify-html');

const initFirebase = require('../initFirebase');

const handlebarsRegisterHelpers = require('../handlebars/handlebarsRegisterHelpers');

handlebarsRegisterHelpers.run();

const partners = express();

partners.use(minifyHTML({
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

partners.engine('hbs', engines.handlebars);
partners.set('view engine', 'hbs');

partners.get('/partners', (request, response) => {
    initFirebase.call(require('./home').get, request, response);
});

/*
const mainPartners = express();
mainPartners.use('/partners', partners);
*/

exports.mainPartners = partners;
