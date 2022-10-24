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

api.get("/v1/user/merge/firebase", (request, response) => {
    return initFirebase.call(require('./usersRequest').requestAllMergeUserProfileWithUserData, request, response);
})

api.get("/v1/user/:uid/merge/firebase", (request, response) => {
    return initFirebase.call(require('./usersRequest').requestMergeUserProfileWithUserData, request, response);
})

api.post("/v1/empresa", (request, response) => {
    return initFirebase.call(require('./users').setEmpresaToUser, request, response);
})


// -- simple-signin ----------------
api.post("/v1/ssin/check", (request, response) => {
    const requestsCall = require('./simple-signin');
    return initFirebase.call(requestsCall.requestCheckUser, request, response);
})

/*
api.post("/v1/ssin/generateLink", (request, response) => {
    const requestsCall = require('./simple-signin');
    return initFirebase.call(requestsCall.requestSimpleSignUrl, request, response);
})

api.post("/v1/ssin/validateToken", (request, response) => {
    const requestsCall = require('./simple-signin');
    return initFirebase.call(requestsCall.requestValidateSimpleSignData, request, response);
})
*/

// Chamado pelo pubsub!
api.post("/v1/account/user/refresh/rtdb", (request, response) => {
    return initFirebase.call(require('../cartos/cartos.users').refreshCartosUserOnRtdb, request, response);
})

// Processamento de Contas

// Inicialização da Conta!
api.post("/v1/account/user/open/account", (request, response) => {
    const cartosRequests = require('../cartos/cartos.accounts.request');
    return initFirebase.call(cartosRequests.requestInitCartosAccount, request, response);
})




/*
api.get("/v1/account/token", (request, response) => {
    if (global.getHost(request, response) !== 'localhost') { return response.status(403).end(); }
    return initFirebase.call(require('./users').account.getUserAccountToken, request, response);
})

// Retorna a situação do usuário e das suas contas
api.get("/v1/account/check", (request, response) => {
    return initFirebase.call(require('./users').account.checkUser, request, response);
})

api.get("/v1/account/create-user", (request, response) => {
    return initFirebase.call(require('./users').account.createUser, request, response);
})

api.get("/v1/account/status/:type", (request, response) => {
    return initFirebase.call(require('./users').account.statusConta, request, response);
})

api.get("/v1/account/status-details/:type", (request, response) => {
    return initFirebase.call(require('./users').account.statusDetails, request, response);
})

api.get("/v1/account/details/:type", (request, response) => {
    return initFirebase.call(require('./users').account.detalhesConta, request, response);
})

api.get("/v1/account/send-email-code", (request, response) => {
    return initFirebase.call(require('./users').account.sendConfirmationCodeToEmail, request, response);
})

api.post("/v1/account/confirm-email-code", (request, response) => {
    return initFirebase.call(require('./users').account.confirmEmailCode, request, response);
})

api.get("/v1/account/abrir-conta/check/:type", (request, response) => {
    return initFirebase.call(require('./users').account.checkAccountData, request, response);
})

api.get("/v1/account/abrir-conta/pf", (request, response) => {
    return initFirebase.call(require('./users').account.abrirContaPessoaFisica, request, response);
})

api.get("/v1/account/abrir-conta/pj", (request, response) => {
    return initFirebase.call(require('./users').account.abrirContaPessoaJuridica, request, response);
})

api.get("/v1/account/send-documents/:type", (request, response) => {
    return initFirebase.call(require('./users').account.enviarDocumentos, request, response);
})

api.get("/v1/account/create-company/:type", (request, response) => {
    return initFirebase.call(require('./users').account.checkZoepayCompany, request, response);
})

api.get("/v1/account/pix-keys", (request, response) => {
    return initFirebase.call(require('./users').account.getPixKeys, request, response);
})






api.get("/v1/cartos/users/user", (request, response) => {
    return initFirebase.call(require('./users').cartos.users.user, request, response);
})

api.get("/v1/cartos/users/register", (request, response) => {
    return initFirebase.call(require('./users').cartos.users.register, request, response);
})

api.get("/v1/cartos/users/send-confirmation-code/email", (request, response) => {
    return initFirebase.call(require('./users').cartos.users.sendConfirmationCodeToEmail, request, response);
})

api.post("/v1/cartos/users/confirm-code/email", (request, response) => {
    return initFirebase.call(require('./users').cartos.users.confirmEmailCode, request, response);
})

*/

/*
api.get("/v1/account/refresh-transactions/:uid?/:page?", (request, response) => {
    return initFirebase.call(require('./users').account.refreshTransactions, request, response);
})
*/


// Chamado pelo pubsub!
api.post("/v1/account/transaction/save/", (request, response) => {
    return initFirebase.call(require('./users').account.saveTransaction, request, response);
})


const users = express();

users.use(cors());
users.options('*', cors());

users.use("/api/users", api);

exports.users = users;
