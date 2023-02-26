'use strict';

import config from './account-info.config';

var ngModule = angular.module('views.account-info', [
])

	.config(config)

	.controller('viewAccountInfoController', function (
		$scope,
		waitUiFactory
	) {

		waitUiFactory.hide();

		$scope.$on('$destroy', function () {
		});

	});


export default ngModule;
