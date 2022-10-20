
const ngModule = angular.module('directives.firestore-reference', [])

	.controller('firestoreReferenceController',
		function (
			$scope,
			appFirestoreHelper
		) {

			if (!$scope.ref || typeof $scope.ref !== 'object') {
				return;
			}

			appFirestoreHelper.getDoc($scope.ref)
				.then(data => {
					var html = data[$scope.field];
					if (data.isFakeData) {
						html += '&nbsp;<i style="color:#dc3545;" class="fas fa-ban"></i>';
					}
					$scope.target.html(html);
				})
				.catch(e => {
					console.error(e);
				})

		}
	)

	.directive('firestoreReference', function () {
		return {
			restrict: 'C',
			scope: {
				ref: '=',
				field: '@'
			},
			controller: 'firestoreReferenceController',
			link: function (scope, element) {
				scope.target = element;
			}
		};
	});

export default ngModule;
