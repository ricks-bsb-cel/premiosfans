'use strict';

import config from './index-user.config';

var ngModule = angular.module('views.index-user', [
])

	.config(config)

	.controller('viewIndexUserController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory,
		waitUiFactory,
		footerBarFactory,
		userService,
		$location
	) {

		$scope.currentUser = null;
		$scope.zoeAccount = null;

		pageHeaderFactory.setModeFull();
		footerBarFactory.show();

		appAuthHelper.ready()

			.then(currentUser => {

				if (!currentUser) {
					$location.path('/index');
					$location.replace();
					return;
				}

				if (currentUser && currentUser.isAnonymous) {
					appAuthHelper.signOut();
					return;
				}

				$scope.currentUser = currentUser;

				return userService.zoepayAccountCurrentUser();
			})

			.then(zoeAccount => {
				$scope.zoeAccount = zoeAccount;
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
