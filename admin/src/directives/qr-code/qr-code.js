
const ngModule = angular.module('directives.qr-code', [])

	.controller('qrCodeController',
		function (
			$scope
		) {
			$scope.url = '/qr/' + btoa($scope.link) + ($scope.size ? '/' + $scope.size : '');
		}
	)

	.directive('qrCode', function () {
		return {
			restrict: 'E',
			scope: {
				link: '=',
				size: '@'
			},
			templateUrl: 'qr-code/qr-code.html',
			controller: 'qrCodeController'
		};
	});

export default ngModule;
