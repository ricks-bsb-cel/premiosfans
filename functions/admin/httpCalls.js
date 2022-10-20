'use strict';

const express = require('express');
const engines = require('consolidate');
const initFirebase = require('../initFirebase');

// const serviceAccount = require("../zoepaygateway-firebase-adminsdk-70x9g-68bccb0435.json");

const handlebarsRegisterHelpers = require('../handlebars/handlebarsRegisterHelpers');

handlebarsRegisterHelpers.run();

const adm = express();

adm.engine('hbs', engines.handlebars);
adm.set('view engine', 'hbs');

adm.get('/', (request, response) => { response.redirect('/adm/login'); })

adm.get('/login', (request, response) => {
    initFirebase.call(require('./login').get, request, response);
});

adm.get('/home', (request, response) => {
    initFirebase.call(require('./home').get, request, response);
});

adm.get('/unauthorized', (request, response) => {
    initFirebase.call(require('./unauthorized').get, request, response);
});

const mainAdm = express();
mainAdm.use('/adm', adm);

exports.mainAdm = mainAdm;
