'use strict';

const ngModule = angular.module('directives.abrir-conta-pj-block-resumo', [])

	.directive('abrirContaPjBlockResumo', function () {
		return {
			restrict: 'E',
			templateUrl: 'abrir-conta-pj-block-resumo/abrir-conta-pj-block-resumo.html',
			scope: {
				data: '='
			}
		};
	});

export default ngModule;
