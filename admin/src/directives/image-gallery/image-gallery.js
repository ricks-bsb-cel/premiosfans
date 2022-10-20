
const ngModule = angular.module('directives.image-gallery', [])

	.controller('imageGalleryController',
		function (
			$scope,
			imageChooserFactory,
			alertFactory
		) {

			$scope.model = $scope.model || [];
			$scope.hideInfo = typeof $scope.hideInfo == 'boolean' ? $scope.hideInfo : false;
			$scope.buttonTitle = $scope.buttonTitle || 'Adicionar Imagem';

			$scope.preview = function (evt) {
				evt.preventDefault();
				$(evt.target).ekkoLightbox({
					alwaysShowClose: true,
					showArrows: false
				});
			}

			$scope.remove = function (img) {
				alertFactory.yesno('Tem certeza que deseja continuar?', 'Excluir imagem').then(function () {
					$scope.model = $scope.model.filter(function (f) { return f.public_id != img.public_id; });
				}).catch(function () { })
			}

			$scope.featured = function (img) {
				var pos = 10;
				$scope.model.forEach(i => {
					i.featured = i.public_id == img.public_id;
					i.order = (i.featured ? 0 : pos += 10);
				})
			}

			$scope.imageChooser = function () {
				var attrs = { slimOptions: {} };

				if ($scope.size) { attrs.slimOptions.size = $scope.size; }
				if ($scope.ratio) { attrs.slimOptions.ratio = $scope.ratio; }
				if ($scope.minSize) { attrs.slimOptions.minSize = $scope.minSize; }

				imageChooserFactory.show(attrs).then(function (data) {
					if (!$scope.model || $scope.model.constructor !== Array) {
						$scope.model = [];
					}
					data.featured = $scope.model.length == 0;
					$scope.model.push(data);
				}).catch(function (e) {
					console.error(e);
				})
			}

		}
	)

	.directive('imageGallery', function (
	) {
		return {
			restrict: 'E',
			templateUrl: 'image-gallery/image-gallery.html',
			controller: 'imageGalleryController',
			scope: {
				model: '=',
				size: '@?',
				ratio: '@?',
				minSize: '@?',
				buttonTitle: '@?',
				hideInfo: '@?'
			}
		};
	});

export default ngModule;
