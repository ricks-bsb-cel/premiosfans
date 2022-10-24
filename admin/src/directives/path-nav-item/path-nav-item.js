
const ngModule = angular.module('directives.path-nav-item', [])

	.controller('pathNavItemController',
		function (
			$rootScope,
			$scope,
			path
		) {
			$rootScope;

			$scope.href = '#!' + path.getPath($scope.path);
			$scope.label = path.getLabel($scope.path);
		}
	)

	.directive('pathNavItem', function () {
		return {
			restrict: 'C',
			scope: {
				path: '@'
			},
			templateUrl: 'path-nav-item/path-nav-item.html',
			controller: 'pathNavItemController'
		};
	});

export default ngModule;
