
const ngModule = angular.module('directives.search-pexels', [])

	.controller('searchPexelsController',
		function (
			$scope,
			pexelsFactory
		) {

			$scope.searchModel = {};
			$scope.loading = false;
			$scope.pexelsResult = null;
			$scope.unused = true;

			$scope.searchFields = [
				{
					key: 'termo',
					type: 'input',
					className: 'capitalize-email',
					templateOptions: {
						label: 'Procurar no Pexels',
						type: 'text',
						maxlength: 32,
						minlength: 3,
						required: true,
						type: 'text'
					},
				}
			];

			$scope.search = function (url) {

				if (!$scope.searchForm.$valid && !url) {
					return;
				}

				$scope.loading = true;
				$scope.unused = false;

				pexelsFactory.searchImage(url || $scope.searchModel.termo, 'landscape').then(function (result) {
					$scope.pexelsResult = result;
					console.info($scope.pexelsResult);
					if (result.total_results == 0) { $scope.searchModel.termo = null; }
					$scope.loading = false;
				}).catch(function (e) {
					console.error(e);
				})

			}

			$scope.select = function (image) {
				$scope.delegate.selected(image);
			}

			if (!$scope.delegate || typeof $scope.delegate.selected != 'function') {
				alert('Erro de programação. A diretiva search-pexels deve ter um delegate.selected.');
			}

		}
	)

	.directive('searchPexels', function () {
		return {
			restrict: 'E',
			scope: {
				delegate: '='
			},
			templateUrl: 'search-pexels/search-pexels.html',
			controller: 'searchPexelsController'
		};
	});

export default ngModule;
