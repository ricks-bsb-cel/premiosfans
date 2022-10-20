
const ngModule = angular.module('directives.folha.itens-contracheque.block-contracheque', [])

	.controller('folhaBlockContraChequeController',
		function (
			$scope,
			collectionItensContraCheque
		) {

			$scope.newItem = _ => {
				collectionItensContraCheque.newItem($scope.tipo)
					.then(success => {
						console.info(success);
					})
					.catch(e => {
						console.error(e);
					})
			}

		})

	.directive('folhaBlockContraCheque', function () {
		return {
			restrict: 'E',
			controller: 'folhaBlockContraChequeController',
			scope: {
				titulo: '@',
				data: '=',
				tipo: '@',
				showReferencia: '=',
				obs: '@'
			},
			templateUrl: 'folha/itens-contracheque/directives/block-contracheque/block-contracheque.html',
		};
	});

export default ngModule;
