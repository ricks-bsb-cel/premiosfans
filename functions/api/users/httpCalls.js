"use strict";

const express = require("express");
const cors = require('cors')
const cookieParser = require('cookie-parser');

const initFirebase = require('../../initFirebase');

const api = express();

api.use(cookieParser());
api.use(cors());

api.options('*', cors());

api.get("/v1/user", (request, response) => {
    return initFirebase.call(require('./users').getUsers, request, response);
})

api.post("/v1/user/find", (request, response) => {
    return initFirebase.call(require('./users').requestFindUserProfileByCpfCelular, request, response);
})

api.post("/v1/appUser/init", (request, response) => {
    return initFirebase.call(require('./users').requestInitAppUser, request, response);
})

api.post("/v1/user/update", (request, response) => {
    return initFirebase.call(require('./users').updateUserProfile, request, response);
})

api.get("/v1/user/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestUserInfo, request, response);
})

api.post("/v1/setSuperUser/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestSetSuperUser, request, response);
})

api.get("/v1/setAdminUser/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestSetAdminUser, request, response);
})

api.post("/v1/empresa", (request, response) => {
    return initFirebase.call(require('./users').setEmpresaToUser, request, response);
})

const users = express();

users.use(cors());
users.options('*', cors());

users.use("/api/users", api);

exports.users = users;
