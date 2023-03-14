'use strict';

const ngModule = angular.module('services.app-database-helper', [])

	.factory('appDatabaseHelper', function (
		appDatabase,
		$q
	) {

		const get = (path) => {
			return $q(resolve => {
				const db = appDatabase.database;
				const ref = appDatabase.ref(db, path);

				appDatabase.get(ref)
					.then(data => {
						resolve(data.val());
					})
			})
		}

		const once = (path) => {
			return $q((resolve, reject) => {

				const db = appDatabase.database;
				const dbRef = appDatabase.ref(db);

				appDatabase.get(appDatabase.child(dbRef, path))

					.then(snapshot => {
						if (snapshot.exists()) {
							return resolve(snapshot.val());
						} else {
							return resolve(null);
						}
					})

					.catch(e => {
						console.error(path, e);
						return reject(e);
					});

			})
		}

		const set = (path, data) => {
			return $q(resolve => {
				const ref = appDatabase.ref(appDatabase.database, path);

				appDatabase.set(ref, data)
					.then(_ => {
						return resolve();
					})
					.catch(e => {
						console.error(e);
						return reject(e);
					})
			})
		}

		return {
			get: get,
			once: once,
			set: set
		}
	})

export default ngModule;