
const ngModule = angular.module('directives.account-card', [])

	.controller('accountCardController',
		function (
			$scope,
			globalFactory
		) {
			$scope.id = 'el_' + globalFactory.generateRandomId();
		}
	)

	.directive('accountCard', function (
	) {
		return {
			restrict: 'E',
			templateUrl: 'account-card/account-card.html',
			controller: 'accountCardController',
			scope: {
				accountData: '='
			}
		};
	});

export default ngModule;
