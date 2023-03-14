const functions = require("firebase-functions");

/* Módulo Home */
exports.app = functions.https.onRequest(require("./app/httpCalls").mainApp);

/* Módulo de Administração */
exports.mainAdm = functions.https.onRequest(require("./admin/httpCalls").mainAdm);

/* Módulo de Parceiros */
exports.mainPartners = functions.https.onRequest(require("./partners/httpCalls").mainPartners);
exports.mainInfluencers = functions.https.onRequest(require("./influencers/httpCalls").mainInfluencers);

/* APIS */
exports.auth = functions.https.onRequest(require("./api/auth/httpCalls").auth);
exports.eeb = functions.https.onRequest(require("./eeb/servicesHttpCalls").eeb);
