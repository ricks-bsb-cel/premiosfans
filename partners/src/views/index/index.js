'use strict';

import config from './index.config';

var ngModule = angular.module('views.index', [
])

	.config(config)

	.controller('viewIndexController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory,
		$location,
		waitUiFactory,
		footerBarFactory
	) {

		$scope.currentUser = null;

		$scope.canCreateAccount = false;
		$scope.continueCreateAccount = false;

		$scope.type = _config.type

		pageHeaderFactory.setModeFull();
		footerBarFactory.hide();

		appAuthHelper.ready()

			.then(_ => {

				$scope.currentUser = appAuthHelper.currentUser;

				if ($scope.currentUser) {
					return appAuthHelper.getUserClaims();
				} else {
					return null;
				}

			})

			.then(customData => {

				$scope.canCreateAccount = !$scope.currentUser;
				$scope.continueCreateAccount = $scope.currentUser && !customData.accountSubmitted;

				if (appAuthHelper.currentUser &&
					!appAuthHelper.currentUser.isAnonymous &&
					customData.accountSubmitted
				) {
					$location.path('/index-user');
					$location.replace();
					return;
				}

				waitUiFactory.hide();
			})

			.catch(e => {
				console.error(e);
			})

		/*
		$scope.$on('$destroy', function () {
			appAuthHelper.destroyNotifyUserDataChanged(userDataChanged);
		});
		*/

	});


export default ngModule;
