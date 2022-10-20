'use strict';

const ngModule = angular.module('directives.block-json-tree', [])

	.controller('blockJsonTreeController',
		function (
			$scope,
		) {
			$scope.editLevel = $scope.editLevel || 'high';
			$scope.collapsedLevel = $scope.collapsedLevel || 1;
		}
	)

	.directive('blockJsonTree', function () {
		return {
			restrict: 'E',
			templateUrl: 'block-json-tree/block-json-tree.html',
			controller: 'blockJsonTreeController',
			scope: {
				jsonData: '=',
				collapsedLevel: '@?',
				editLevel: '@?'
			}
		};
	});

export default ngModule;
