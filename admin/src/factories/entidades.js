'use strict';

let ngModule = angular.module('factories.entidades', [])

	.factory('entidadesFactory',

		function (
			$q,
			appDatabase,
			collectionAdmConfigPath
		) {

			var cache = {};

			const getConfig = type => {
				return $q((resolve, reject) => {
					let result = {};

					if (cache[type]) {
						return resolve(cache[type]);
					}

					const db = appDatabase.database;
					const ref = appDatabase.ref(db, `entidade/${type}`);

					appDatabase.get(ref)

						.then(data => {
							result.type = data.val();

							return collectionAdmConfigPath.getByHref(`/entidades/${type}`);
						})

						.then(collectionAdmConfigPathResult => {
							result.path = collectionAdmConfigPathResult;

							cache[type] = result;

							return resolve(result);
						})

						.catch(e => {
							return reject(e);
						})

				})
			};

			return {
				getConfig: getConfig
			};
		}
	);

export default ngModule;
