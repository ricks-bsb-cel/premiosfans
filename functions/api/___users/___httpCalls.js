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

api.post("/v1/user/update", (request, response) => {
    return initFirebase.call(require('./users').updateUserProfile, request, response);
})

api.get("/v1/user/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestUserInfo, request, response);
})

api.post("/v1/set-super-user/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestSetSuperUser, request, response);
})

api.post("/v1/remove-super-user/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestRemoveSuperUser, request, response);
})

api.post("/v1/set-admim-user/:uid", (request, response) => {
    return initFirebase.call(require('./users').requestSetAdminUser, request, response);
})

api.post("/v1/empresa", (request, response) => {
    return initFirebase.call(require('./users').setEmpresaToUser, request, response);
})


/* ------------------------------------------------------- */

api.post("/v2/get-users", (request, response) => {
    return initFirebase.call(require('./users-v2').requestGetUsers, request, response);
})

const users = express();

users.use(cors());
users.options('*', cors());

users.use("/api/users", api);

exports.users = users;
