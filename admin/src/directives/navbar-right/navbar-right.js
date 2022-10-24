
const ngModule = angular.module('directives.navbar-right', [])

	.controller('navbarRightController',
		function (
			$scope,
			firebaseProvider,
			alertFactory,
			blockUiFactory,
			$timeout
		) {

			$scope.logout = function () {
				alertFactory
					.yesno('Tem certeza que deseja se desconectar do sistema?')
					.then(function () {
						blockUiFactory.start();
						firebaseProvider.signout();
						
						$timeout(function () {
							debugger;
							window.location.href = '/adm/login';
						}, 1000)
					});
			}
			
		}
	)

	.directive('navbarRight', function () {
		return {
			restrict: 'C',
			templateUrl: 'navbar-right/navbar-right.html',
			controller: 'navbarRightController'
		};
	});

export default ngModule;
