
const ngModule = angular.module('directives.account-details', [])

	.controller('accountDetailsController',
		function (
			$scope
		) {
			console.info($scope.accountData);
		}
	)

	.directive('accountDetails', function (
	) {
		return {
			restrict: 'E',
			templateUrl: 'account-details/account-details.html',
			controller: 'accountDetailsController',
			scope: {
				accountData: '=',
				title: '@',
				type: '@'
			}
		};
	});

export default ngModule;
