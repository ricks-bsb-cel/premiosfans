'use strict';

const ngModule = angular.module('services.app-config', [])

	.factory('appConfig', function (
		globalFactory,
		appDatabase,
		appDatabaseHelper
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

			appDatabaseHelper.get('globalConfig')
				.then(data => {
					globalConfig = data;
					callback();
				})
				.catch(e => {
					console.error(e);
				})
		}

		const _initEmpresa = idEmpresa => {

			if (!idEmpresa) return;


			appDatabaseHelper.get('configEmpresa/' + idEmpresa)
				.then(data => {
					globalConfig = {
						...globalConfig,
						...data
					}
				})
				.catch(e => {
					console.error(e)
				})
		}

		const appProfile = _ => {
			const result = _get("/appProfile/default");
			const host = _get("/appProfile/" + location.hostname);

			return {
				...result,
				...host
			}
		}

		return {
			init: _init,
			initEmpresa: _initEmpresa,
			get: _get,
			appProfile: appProfile
		}

	});

export default ngModule;