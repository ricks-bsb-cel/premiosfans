
const ngModule = angular.module('directives.bell', [])
	.directive('bell', function () {
		return {
			restrict: 'E',
			replace: true,
			scope: {
				animate: '=',
				color: '=?'
			},
			templateUrl: 'bell/bell.html'
		};
	});

export default ngModule;
