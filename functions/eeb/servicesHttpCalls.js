"use strict";

const express = require("express");
const cors = require('cors')
const cookieParser = require('cookie-parser');

const initFirebase = require('../initFirebase');

const api = express();

api.use(cookieParser());
api.use(cors());
api.options('*', cors());

// Subscrições apontam para cá...
api.post("/v1/receiver/:method", (request, response) => {
    const receiver = require('./eventBusServicePubSubReceiver');
    initFirebase.call(receiver.pubSubReceiver, request, response);
})

// Subscrições em DeadLettering apontam para cá...
api.post("/v1/dead-lettering", (request, response) => {
    const deadLettering = require('./eventBusServicePubSubDeadLetterReceiver');
    initFirebase.call(deadLettering.pubSubDeadLetterReceiver, request, response);
})

// Tasks apontam para cá
api.post("/v1/task-receiver/:method", (request, response) => {
    const receiver = require('./eventBusServiceTaskReceiver');
    initFirebase.call(receiver.taskReceiver, request, response);
})

// Serviços são definidos abaixo...
api.get("/v1/test", (request, response) => {
    initFirebase.call(require('./services/test').callRequest, request, response);
})

api.post("/v1/test", (request, response) => {
    initFirebase.call(require('./services/test').callRequest, request, response);
})

api.post("/v1/whr/:source/:type?", (request, response) => {
    initFirebase.call(require('./services/webhook').callRequest, request, response);
})


api.post("/v1/generate-templates", (request, response) => {
    initFirebase.call(require('./services/generateTemplates').callRequest, request, response);
})

api.post("/v1/generate-one-template", (request, response) => {
    initFirebase.call(require('./services/generateOneTemplate').callRequest, request, response);
})


api.post("/v1/ativar-campanha", (request, response) => {
    initFirebase.call(require('./services/ativarCampanha').callRequest, request, response);
})

api.post("/v1/generate-ns-premio", (request, response) => {
    initFirebase.call(require('./services/generateNumerosDaSortePremio').callRequest, request, response);
})

api.post("/v1/generate-titulo", (request, response) => {
    initFirebase.call(require('./services/generateTitulo').callRequest, request, response);
})

api.post("/v1/pagar-compra", (request, response) => {
    initFirebase.call(require('./services/pagarCompra').callRequest, request, response);
})

api.post("/v1/pagar-titulo", (request, response) => {
    initFirebase.call(require('./services/pagarTitulo').callRequest, request, response);
})

api.post("/v1/generate-premio-titulo", (request, response) => {
    initFirebase.call(require('./services/generatePremioTitulo').callRequest, request, response);
})

api.post("/v1/link-ns-premio", (request, response) => {
    initFirebase.call(require('./services/linkNumeroDaSortePremioTitulo').callRequest, request, response);
})

api.post("/v1/check-one-titulo-compra", (request, response) => {
    initFirebase.call(require('./services/checkTituloCompra').callRequest, request, response);
})

api.post("/v1/check-titulos-campanha", (request, response) => {
    initFirebase.call(require('./services/checkTitulosCampanha').callRequest, request, response);
})

api.post("/v1/generate-dashboard-data", (request, response) => {
    initFirebase.call(require('./services/generateDashboardData').callRequest, request, response);
})

api.post("/v1/purge-campanha", (request, response) => {
    initFirebase.call(require('./services/purgeCampanha').callRequest, request, response);
})

api.post("/v1/send-email-titulo", (request, response) => {
    initFirebase.call(require('./services/sendEmailTitulo').callRequest, request, response);
})

/* Users */

api.get("/v1/user/get-profile/:uid", (request, response) => {
    initFirebase.call(require('./services/usersGetUserProfile').callRequest, request, response);
})

api.get("/v1/user/update-profile", (request, response) => {
    initFirebase.call(require('./services/usersUpdateUserProfile').callRequest, request, response);
})

api.post("/v1/user/update-custom-config", (request, response) => {
    initFirebase.call(require('./services/usersUpdateUserCustomConfig').callRequest, request, response);
})

api.get("/v1/user/revoke-token/:uid", (request, response) => {
    initFirebase.call(require('./services/usersRevokeUserToken').callRequest, request, response);
})

/* Cartos  v1 */

api.post("/v1/cartos/user-credential", (request, response) => {
    initFirebase.call(require('./services/cartosGetUserCredential').callRequest, request, response);
})

api.post("/v1/cartos/update-account-list", (request, response) => {
    initFirebase.call(require('./services/cartosUpdateAccountList').callRequest, request, response);
})

api.post("/v1/cartos/update-account-balance", (request, response) => {
    initFirebase.call(require('./services/cartosUpdateBalance').callRequest, request, response);
})

api.post("/v1/cartos/update-account-extract", (request, response) => {
    initFirebase.call(require('./services/cartosUpdateExtract').callRequest, request, response);
})

api.post("/v1/cartos/update-pix-keys", (request, response) => {
    initFirebase.call(require('./services/cartosUpdatePixKeys').callRequest, request, response);
})

api.post("/v1/cartos/generate-pix", (request, response) => {
    initFirebase.call(require('./services/cartosGeneratePix').callRequest, request, response);
})

/* Cartos

api.post("/v1/pay/user-credential", (request, response) => {
    initFirebase.call(require('./services/cartos/getUserCredential').callRequest, request, response);
})

api.post("/v1/pay/account-list", (request, response) => {
    initFirebase.call(require('./services/cartos/accountList').callRequest, request, response);
})

api.post("/v1/pay/pix-keys-list", (request, response) => {
    initFirebase.call(require('./services/cartos/pixKeysList').callRequest, request, response);
})

api.post("/v1/pay/pix-key-delete", (request, response) => {
    initFirebase.call(require('./services/cartos/pixKeysDelete').callRequest, request, response);
})

api.post("/v1/pay/pix-key-create", (request, response) => {
    initFirebase.call(require('./services/cartos/pixKeysCreate').callRequest, request, response);
})

api.post("/v1/pay/pix-create", (request, response) => {
    initFirebase.call(require('./services/cartos/pixCreate').callRequest, request, response);
})

*/

const eeb = express();

eeb.use(cors());
eeb.options('*', cors());

eeb.use("/api/eeb", api);

exports.eeb = eeb;
