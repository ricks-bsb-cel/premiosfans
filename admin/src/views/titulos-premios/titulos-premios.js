'use strict';

import config from './titulos-premios.config';

const ngModule = angular.module('views.titulos-premios', [
])
	.config(config)

	.controller('viewTitulosPremiosController', function (
		$scope,
		appAuthHelper,
		collectionTitulosPremios,
		toastrFactory
	) {

		$scope.collectionTitulosPremios = collectionTitulosPremios;

		$scope.filter = {

			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.limit = 60;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionTitulosPremios.collection.startSnapshot(attrFilter);

			}

		}

		appAuthHelper.ready()
			.then(_ => {
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionTitulosPremios.collection.destroySnapshot();
		});


	});


export default ngModule;
