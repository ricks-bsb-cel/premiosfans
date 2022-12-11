
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

					$scope.element.find('.fa.fa-refresh').hide();
				})

		}
	)

	.directive('userPanel', function () {
		return {
			restrict: 'E',
			templateUrl: 'user-panel/user-panel.html',
			controller: 'userPanelController',
			link: function (scope, element, attr) {
				scope.element = element;
			}
		};
	});

export default ngModule;
