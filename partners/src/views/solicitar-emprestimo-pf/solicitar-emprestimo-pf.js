'use strict';

import config from './solicitar-emprestimo-pf.config';

var ngModule = angular.module('views.solicitar-emprestimo-block', [
])

	.config(config)

	.controller('viewSolicitarEmprestimoPFController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory
	) {

		$scope.ready = false;

		pageHeaderFactory.setModeLight('Simule seu Emprestimo');

		appAuthHelper.ready()
			.then(_ => {
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
