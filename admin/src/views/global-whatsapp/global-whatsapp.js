'use strict';

import config from './global-whatsapp.config';

var ngModule;

ngModule = angular.module('views.globalWhatsapp', [])
	.config(config)

	.controller('viewGlobalWhatsappController', function (
		$scope,
		navbarTopLeftFactory,
		firebaseService
	) {

		navbarTopLeftFactory.reset(false);

		$scope.user = null;
		$scope.status = null;
		$scope.idEmpresa = 'global';

		firebaseService.getProfile(userProfile => {
			$scope.user = userProfile.user;
		})

		/*
		firebaseService.registerListenersAuthStateChanged(function (user, adm) {
			if (user) {
				$scope.user = user;
			}
		})
		*/

		firebaseService.init();

	});


export default ngModule;
