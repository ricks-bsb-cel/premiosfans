'use strict';

const ngModule = angular.module('services.app-database-helper', [])

	.factory('appDatabaseHelper', function (
		appDatabase,
		$q
	) {

		const _get = path => {
			return $q((resolve, reject) => {
				const db = appDatabase.database;
				const ref = appDatabase.ref(db);
				const query = appDatabase.child(ref, path);

				appDatabase.get(query)
					.then(data => {
						return resolve(data.val() || null);
					})
					.catch(e => {
						return reject(e);
					})
			})
		}

		const _once = (path) => {
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

		const _set = (path, data) => {
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
			get: _get,
			set: _set,
			once: _once
		}
	})

export default ngModule;