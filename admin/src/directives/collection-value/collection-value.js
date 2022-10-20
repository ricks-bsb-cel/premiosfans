
const ngModule = angular.module('directives.collection-value', [])

	.controller('collectionValueController',
		function (
			$scope
		) {
			$scope.value = 'teste';
		}
	)

	.directive('collectionValue', function () {
		return {
			restrict: 'E',
			template: '{{value}}',
			controller: 'collectionValueController',
			scope: {
				collection: '@',
				field: '@',
				docId: '='
			}
		};
	});

export default ngModule;
