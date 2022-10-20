
const ngModule = angular.module('directives.moeda', [])

	.controller('moedaController',
		function (
			$scope
		) {

			$scope.moeda = $scope.moeda || 'R$';
			$scope.saldo = ($scope.valor / 100).toFixed(2);

		}
	)

	.directive('moeda', function () {
		return {
			restrict: 'E',
			templateUrl: 'moeda/moeda.html',
			controller: 'moedaController',
			scope: {
				valor: '=',
				moeda: '@?'
			}
		};
	});

export default ngModule;
