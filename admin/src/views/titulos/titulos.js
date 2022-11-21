'use strict';

import config from './titulos.config';

const ngModule = angular.module('views.titulos', [
])
	.config(config)

	.controller('viewTitulosController', function (
		$scope,
		appAuthHelper,
		collectionTitulos,
		toastrFactory
	) {

		$scope.collectionTitulos = collectionTitulos;

		$scope.filter = {

			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.limit = 60;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionTitulos.collection.startSnapshot(attrFilter);

			}

		}

		appAuthHelper.ready()
			.then(_ => {
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionTitulos.collection.destroySnapshot();
		});


	});


export default ngModule;
