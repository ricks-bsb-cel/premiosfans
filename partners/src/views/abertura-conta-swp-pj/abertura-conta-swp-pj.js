'use strict';

import config from './abertura-conta-swp-pj.config';

var ngModule = angular.module('views.abertura-conta-swp-pj', [
])

	.config(config)

	.controller('viewAberturaContaSwiperPJController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory
	) {

		$scope.ready = false;

		pageHeaderFactory.setModeLight('Abertura de Conta');

		appAuthHelper.ready()
			.then(currentUser => {

 				/*
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
				*/

				$scope.ready = true;
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
