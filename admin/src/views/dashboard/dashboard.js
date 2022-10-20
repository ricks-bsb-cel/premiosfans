'use strict';

import config from './dashboard.config';

const ngModule = angular.module('views.dashboard', [
])

	.config(config)

	.controller('viewDashboardController', function (
		$scope,
		navbarTopLeftFactory
	) {

		$scope.ready = false;
		$scope.dados = [];

		navbarTopLeftFactory.reset(false);

		$scope.$on('$destroy', function () {
		});

	});

export default ngModule;
