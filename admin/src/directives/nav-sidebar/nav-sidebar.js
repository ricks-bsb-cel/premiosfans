
const ngModule = angular.module('directives.navigation', [])

	.controller(
		'navigationController',
		function (
			$scope,
			firebaseService,
			collectionAdmConfigPath
		) {

			$scope.user = null;
			$scope.collectionAdmConfigPath = collectionAdmConfigPath;
			$scope.options = [];

			firebaseService.getProfile(userProfile => {
				$scope.user = userProfile.user;
				$scope.collectionAdmConfigPath.collection.getSnapshot({});
			})
		}
	)

	.directive('navigation', function () {
		return {
			restrict: 'E',
			scope: {
				name: '@'
			},
			controller: 'navigationController',
			templateUrl: 'navigation/navigation.html'
		};
	});

export default ngModule;
