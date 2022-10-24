const functions = require("firebase-functions");

/* Módulo de Administração */
exports.mainAdm = functions.https.onRequest(require("./admin/httpCalls").mainAdm);

/* APIS */
exports.auth = functions.https.onRequest(require("./api/auth/httpCalls").auth);
exports.users = functions.https.onRequest(require("./api/users/httpCalls").users);
