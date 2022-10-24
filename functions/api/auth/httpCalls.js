'use strict';

const express = require("express");
const cookieParser = require('cookie-parser');
const initFirebase = require('../../initFirebase');

const api = express();

api.use(cookieParser());

api.get("/v1/token", (request, response) => {
    initFirebase.call(require('./auth').requestCreateToken, request, response);
})

const auth = express();
auth.use("/api/auth", api);

exports.auth = auth;
