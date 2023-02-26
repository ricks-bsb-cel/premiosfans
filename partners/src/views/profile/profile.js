'use strict';

import config from './profile.config';

var ngModule = angular.module('views.profile', [
])

	.config(config)

	.controller('viewProfileController', function (
		$scope,
		waitUiFactory
	) {

		waitUiFactory.hide();

		$scope.$on('$destroy', function () {
		});

	});


export default ngModule;
