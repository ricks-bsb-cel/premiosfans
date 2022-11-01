const admin = require("firebase-admin");

let app = null;

exports.call = (f, request, response, parm) => {
	parm = parm || {};

	init()
		.then(_ => {
			return f(request, response, parm);
		})

		.catch(e => {
			console.error(e);
		})
}

const init = _ => {
	return new Promise(resolve => {
		if (app) {
			return resolve(app);
		} else {
			app = admin.initializeApp({
				databaseURL: "https://premios-fans-default-rtdb.firebaseio.com"
			});

			return resolve(app);
		}
	})
}

exports.init = init;
