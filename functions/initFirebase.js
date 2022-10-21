const admin = require("firebase-admin");
const secret = require("./secretManager");

var app = null;

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
		try {

			if (app) {
				// console.info('App já está instanciado...');
				return resolve(app);
			} else {

				// Se não iniciado, carrega os secrets...
				// console.info('Instanciando app...');

				var getSecrets = [
					secret.get("premios-fans-firebase-adminsdk"),
					secret.get("premios-fans-firebase-init")
				];

				return Promise.all(getSecrets)
					.then(secrets => {

						// var serviceAccount = secrets[0] || null;
						// var initFirebase = secrets[1] || null;

						// Inicializa o App
						// initFirebase.credential = admin.credential.cert(serviceAccount);

						// console.info(initFirebase);
						// app = admin.initializeApp({}serviceAccount);

						// initFirebase.credential = admin.credential.cert(serviceAccount);

						// app = admin.initializeApp(initFirebase);
						app = admin.initializeApp();

						return resolve(app);
					})

					.catch(e => {
						console.error(e);
						return resolve(admin);
					})

			}
		}
		catch (e) {
			console.error("initApp error", e);
			return resolve(admin);
		}
	})
}


exports.init = init;