'use strict';

import config from './account-status.config';

var ngModule = angular.module('views.account-status', [
])

	.config(config)

	.controller('viewAccountStatusController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory,
		waitUiFactory
	) {

		pageHeaderFactory.setModeLight('Minhas contas');

		$scope.ready = false;


		appAuthHelper.ready()
			.then(_ => {

				$scope.ready = true;
				waitUiFactory.hide();

			})
			.catch(e => {
				console.info(e);
			})


		/*
		$scope.$on('$destroy', function () {
		});
		*/

	});


export default ngModule;
