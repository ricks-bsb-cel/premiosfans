
const ngModule = angular.module('directives.account-error-details', [])

	.controller('accountErrorDetailsController',
		function (
			$scope
		) {

			$scope.details = null;

			/*
			userAccounts.statusDetails($scope.type)
				.then(details => {
					$scope.details = details;
				})
			*/

		}
	)

	.directive('accountErrorDetails', function () {
		return {
			restrict: 'E',
			templateUrl: 'account-error-details/account-error-details.html',
			controller: 'accountErrorDetailsController',
			scope: {
				type: '@',
				account: '='
			}
		};
	});

export default ngModule;
