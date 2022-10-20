
const ngModule = angular.module('directives.emoticon-tags', [])
	.controller('emoticonTagsController', function (
		$scope
	) {

		$scope.aTags = [];
		$scope.model = $scope.model || [];

		for (let i = 0; i < $scope.tags.length; i += 2) {
			$scope.aTags.push($scope.tags.substr(i, 2));
		}

		$scope.select = function (tag) {
			if ($scope.model.includes(tag)) {
				$scope.model = $scope.model.filter(function (f) { return f != tag; });
			} else {
				$scope.model.push(tag);
			}
		}

	})
	.directive('emoticonTags', function () {
		return {
			restrict: 'E',
			controller: 'emoticonTagsController',
			scope: {
				tags: '=',
				model: '='
			},
			templateUrl: 'emoticon-tags/emoticon-tags.html'
		};
	});

export default ngModule;
