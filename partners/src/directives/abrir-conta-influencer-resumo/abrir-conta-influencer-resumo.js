'use strict';

const ngModule = angular.module('directives.abrir-conta-influencer-resumo', [])

	.directive('abrirContaInfluencerResumo', function () {
		return {
			restrict: 'E',
			templateUrl: 'abrir-conta-influencer-resumo/abrir-conta-influencer-resumo.html',
			scope: {
				data: '='
			}
		};
	});

export default ngModule;
