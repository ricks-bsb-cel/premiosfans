'use strict';

const ngModule = angular.module('directives.abrir-conta-pf-block-resumo', [])

	.controller('abrirContaPFResumoController',
		function (
			$scope
		) {

		}
	)

	.directive('abrirContaPfBlockResumo', function () {
		return {
			restrict: 'E',
			templateUrl: 'abrir-conta-pf-block-resumo/abrir-conta-pf-block-resumo.html',
			controller: 'abrirContaPFResumoController',
			scope: {
				data: '='
			}
		};
	});

export default ngModule;
