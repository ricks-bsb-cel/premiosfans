
const ngModule = angular.module('directives.help-tip', [])
	.directive('helpTip', function () {
		return {
			restrict: 'E',
			replace: true,
			scope: {
				tip: '@'
			},
			templateUrl: 'help-tip/help-tip.html'
		};
	});

export default ngModule;
