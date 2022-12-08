
const ngModule = angular.module('directives.user-panel', [])

	.controller('userPanelController',
		function (
			$scope,
			appAuthHelper
		) {

			appAuthHelper.ready()
				.then(_ => {
					$scope.userName = appAuthHelper.user.displayName || appAuthHelper.user.email;
					$scope.email = appAuthHelper.user.email;
				})

		}
	)

	.directive('userPanel', function () {
		return {
			restrict: 'E',
			templateUrl: 'user-panel/user-panel.html',
			controller: 'userPanelController'
		};
	});

export default ngModule;
