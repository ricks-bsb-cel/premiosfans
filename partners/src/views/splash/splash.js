'use strict';

import config from './splash.config';

var ngModule = angular.module('views.splash', [
])

	.config(config)

	.controller('viewSplashController', function (
		appAuthHelper,
		pageHeaderFactory,
		footerBarFactory,
		$location
	) {

		pageHeaderFactory.setModeNone();
		footerBarFactory.hide();

		appAuthHelper.ready()

			.then(currentUser => {

				if (!currentUser) {
					$location.path('/index');
				} else {

					if (currentUser.isAnonymous && currentUser.customData.accountSubmitted) {
						$location.path('/index-user');
						$location.replace();
						return;
					}

					if (currentUser.isAnonymous || currentUser.customData.accountSubmitted) {
						$location.path('/index');
						$location.replace();
						return;
					}

					appAuthHelper.signOut();
				}

			})

			.catch(e => {
				console.error(e);
			})


	});


export default ngModule;
