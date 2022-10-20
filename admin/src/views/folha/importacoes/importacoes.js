'use strict';

import config from './importacoes.config';

const ngModule = angular.module('views.folha.importacoes', [
])
	.config(config)

	.controller('viewFolhaImportacoesController', function (
		$scope,
		navbarTopLeftFactory,
		alertFactory,
		toastrFactory
	) {

		$scope.ready = false;

		navbarTopLeftFactory.extend({
			label: 'Uma Opção Qualquer',
			onClick: function () {
				alertFactory.info("Você clicou!", "Parabéns!");
				toastrFactory.success("Parabéns! Você clicou!")
			},
			icon: 'fas fa-plus'
		});

		const init = _ => {
			$scope.ready = true;
		}

		$scope.$on('$viewContentLoaded', function () {
			init();
		});

	});


export default ngModule;
