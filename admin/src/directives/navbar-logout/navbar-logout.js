
const ngModule = angular.module('directives.navbar-logout', [])

	.controller('navbarLogoutController',
		function (
			$scope,
			appAuthHelper,
			blockUiFactory
		) {

			$scope.logout = function () {
				blockUiFactory.start();
				appAuthHelper.signOut();
			}

		}
	)

	.directive('navbarLogout', function () {
		return {
			restrict: 'A',
			templateUrl: 'navbar-logout/navbar-logout.html',
			controller: 'navbarLogoutController'
		};
	});

export default ngModule;
