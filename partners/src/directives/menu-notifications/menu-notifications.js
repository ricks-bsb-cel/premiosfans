
const ngModule = angular.module('directives.menu-notifications', [])

	.controller('menuNotificationsController',
		function (
			$scope
		) {

		}
	)

	.directive('menuNotifications', function () {
		return {
			restrict: 'E',
			templateUrl: 'menu-notifications/menu-notifications.html',
			controller: 'menuNotificationsController'
		};
	});

export default ngModule;
