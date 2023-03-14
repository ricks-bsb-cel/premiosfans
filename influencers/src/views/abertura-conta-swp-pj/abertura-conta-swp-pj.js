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

		pageHeaderFactory.setModeLight('Cadastro de Influencers');

		appAuthHelper.ready().then(currentUser => {
			$scope.ready = true;
		}).catch(e => {
			console.info(e);
		});

	});


export default ngModule;
