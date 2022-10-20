import config from './global-dashboard.config';

'use strict';

var ngModule;

(function () {

	ngModule = angular.module('views.global-dashboard', [
	])

		.config(config)

		.controller('viewGlobalDashboardController', function (
			navbarTopLeftFactory
		) {
			navbarTopLeftFactory.reset(false);
		});

})();

export default ngModule;
