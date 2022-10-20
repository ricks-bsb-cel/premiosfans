'use strict';

import config from './dashboard-rh.config';
import directiveBlockFuncionarios from './directives/block-funcionarios/block-funcionarios';
import directiveBlockPagamentos from './directives/block-pagamentos/block-pagamentos';

const ngModule = angular.module('views.dashboard-rh', [
	directiveBlockFuncionarios.name,
	directiveBlockPagamentos.name
])

	.config(config)

	.controller('viewDashboardRHController', function (
		$scope,
		navbarTopLeftFactory
	) {

		$scope.ready = false;
		$scope.dados = [];

		navbarTopLeftFactory.reset(false);

		$scope.$on('$destroy', function () {
		});

	});

export default ngModule;
