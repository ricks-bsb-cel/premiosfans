const admin = require("firebase-admin");
const secret = require("./secretManager");

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
		try{

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

						var serviceAccount = secrets[0];
						var initFirebase = secrets[1];

						// Inicializa o App
						initFirebase.credential = admin.credential.cert(serviceAccount);

						app = admin.initializeApp(initFirebase);

						return resolve(app);
					})

					.catch(e => {
						console.error("getSecrets error", e);
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