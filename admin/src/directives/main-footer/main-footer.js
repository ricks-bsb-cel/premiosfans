
const ngModule = angular.module('directives.main-footer', [])

	.controller('mainFooterController',
		function (
			$scope,
			appAuthHelper
		) {
			$scope.userProfile = null;
			
			appAuthHelper.ready().then(_ => {
				$scope.userProfile = appAuthHelper.profile;
			})
		}
	)

	.directive('mainFooter', function () {
		return {
			restrict: 'C',
			templateUrl: 'main-footer/main-footer.html',
			controller: 'mainFooterController'
		};
	});

export default ngModule;
