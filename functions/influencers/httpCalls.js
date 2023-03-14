'use strict';

const express = require('express');
const engines = require('consolidate');
const minifyHTML = require('express-minify-html');

const initFirebase = require('../initFirebase');

const handlebarsRegisterHelpers = require('../handlebars/handlebarsRegisterHelpers');

handlebarsRegisterHelpers.run();

const influencers = express();

influencers.use(minifyHTML({
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

influencers.engine('hbs', engines.handlebars);
influencers.set('view engine', 'hbs');

influencers.get('/influencers', (request, response) => {
    initFirebase.call(require('./home').get, request, response);
});

exports.mainInfluencers = influencers;
