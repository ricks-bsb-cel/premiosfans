
const ngModule = angular.module('directives.user-panel', [])

	.controller('userPanelController',
		function (
			$scope,
			appAuthHelper,
			globalParms
		) {

			$scope.userImg = globalParms.logoImg;
			$scope.userName = null;
			$scope.superUser = false;
			$scope.ready = false;

			appAuthHelper.ready().then(_ => {
				$scope.userImg = appAuthHelper.user.photoURL || globalParms.logoImg;
				$scope.userName = appAuthHelper.user.displayName || appAuthHelper.user.email;
				$scope.email = appAuthHelper.user.email;
				if (appAuthHelper.profile.user.superUser) {
					$scope.superUser = true;
				}
				$scope.ready = true;
			})

		}
	)

	.directive('userPanel', function () {
		return {
			restrict: 'C',
			templateUrl: 'user-panel/user-panel.html',
			controller: 'userPanelController'
		};
	});

export default ngModule;
