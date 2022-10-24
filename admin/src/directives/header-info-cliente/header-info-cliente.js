
const ngModule = angular.module('directives.header-info-cliente', [])
	.controller('headerInfoClienteController',
		function (
			$scope,
			firebaseService,
			globalFactory
		) {
			$scope.user = null;
			$scope.cpfFormatted = null;

			firebaseService.getProfile(userProfile => {
				$scope.user = userProfile.user;
			})

			firebaseService.init();
		})

	.directive('headerInfoCliente', function () {
		return {
			restrict: 'E',
			replace: true,
			controller: 'headerInfoClienteController',
			templateUrl: 'header-info-cliente/header-info-cliente.html'
		};
	});

export default ngModule;
