'use strict';

const ngModule = angular.module('services.app', [])

	.factory('appService', function (
		appFirestore,
		appDatabase,
		appStorage,
		appAuthHelper
	) {

		let _app = null;

		const init = (app) => {
			_app = app;

			appFirestore.init(app);
			appDatabase.init(app);
			appStorage.init(app);
			appAuthHelper.init();
		}

		return {
			init: init
		}

	})

export default ngModule;
