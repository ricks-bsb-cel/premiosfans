
const ngModule = angular.module('directives.retry-login', [])

	.controller('retryLoginController',
		function (
			$scope,
			firebaseProvider,
		) {
			$scope.retryLogin = function () {
				window.location.reload();
			}
		}
	)

	.directive('retryLogin', function () {
		return {
			restrict: 'E',
			templateUrl: 'retry-login/retry-login.html',
			controller: 'retryLoginController'
		};
	});

export default ngModule;
