
const ngModule = angular.module('directives.block-contas', [])

	.controller('blockContasController',
		function (
			$scope,
			collectionContas,
			appAuthHelper
		) {

			$scope.collectionContas = null;

			appAuthHelper.ready().then(_ => {
				$scope.collectionContas = collectionContas;
			})

		}
	)

	.directive('blockContas', function () {
		return {
			restrict: 'E',
			templateUrl: 'block-contas/block-contas.html',
			controller: 'blockContasController',
			scope: {
				model: '='
			}
		};
	});

export default ngModule;
