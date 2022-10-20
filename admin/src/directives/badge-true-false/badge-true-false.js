
const ngModule = angular.module('directives.badge-true-false', [])
	.directive('badgeTrueFalse', function () {
		return {
			restrict: 'E',
			scope: {
				value: '='
			},
			templateUrl: 'badge-true-false/badge-true-false.html'
		};
	});

export default ngModule;
