'use strict';

const ngModule = angular.module('services.app-config', [])

	.factory('appConfig', function (
		globalFactory,
		appDatabase
	) {

		let globalConfig = null;

		const _get = path => {
			if (path.startsWith('/')) { 
				path = path.substr(1);
			}
			path = globalFactory.replace(path, '.', '_');
			path = globalFactory.replace(path, '/', '.');
			return _.get(globalConfig, path) || {}
		}

		const _init = callback => {
			const db = appDatabase.database;
			var ref = appDatabase.ref(db, 'globalConfig');

			appDatabase.onValue(ref, data => {
				globalConfig = data.val() || {};
				callback();
			}, {
				onlyOnce: true
			});
		}

		const appProfile = _ => {
			return _get("/appProfile/default");
		}

		return {
			init: _init,
			get: _get,
			appProfile: appProfile
		}

	})

export default ngModule;