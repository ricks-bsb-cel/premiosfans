'use strict';

const ngModule = angular.module('services.app', [])

	.factory('appService', function (
		appFirestore,
		appDatabase,
		appAuthHelper
	) {

		var app = null;

		const init = (a) => {
			app = a;

			appFirestore.init(app);
			appDatabase.init(app);
			appAuthHelper.init();
		}

		return {
			init: init
		}

	})

export default ngModule;
