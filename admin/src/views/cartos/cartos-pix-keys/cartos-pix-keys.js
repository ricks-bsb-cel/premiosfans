'use strict';

import config from './cartos-pix-keys.config';

const ngModule = angular.module('views.cartos-pix-keys', [
])
	.config(config)

	.controller('viewCartosPixKeysController', function (
		$scope,
		appAuthHelper,
		collectionCartosPixKeys,
		toastrFactory
	) {

		$scope.collectionCartosPixKeys = collectionCartosPixKeys;

		const startSnapshot = termo => {
			var attrFilter = { filter: [] };

			if (termo) {
				attrFilter.filter.push({ field: "keywords", operator: "array-contains", value: termo });
			} else {
				attrFilter.limit = 60;
				toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
			}

			$scope.collectionCartosPixKeys.collection.startSnapshot(attrFilter);
		}

		$scope.filter = {
			run: function (termo) {
				startSnapshot(termo);
			}
		}

		$scope.remove = pixkey => {
			console.info(pixkey);
		}

		appAuthHelper.ready()
			.then(_ => {
				// startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionCartosPixKeys.collection.destroySnapshot();
		});

	});


export default ngModule;
