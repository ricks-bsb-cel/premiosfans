'use strict';

import config from './abertura-conta-swp-influencer.config';

var ngModule = angular.module('views.abertura-conta-swp-influencer', [
])

	.config(config)

	.controller('viewAberturaContaSwiperInfluencerController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory
	) {
		$scope.ready = false;

		pageHeaderFactory.setModeLight('Cadastro de Influencer');

		appAuthHelper.ready().then(_ => {
			$scope.ready = true;
		}).catch(e => {
			console.info(e);
		});

	});


export default ngModule;
