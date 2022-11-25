'use strict';

import config from './titulos-premios.config';

const ngModule = angular.module('views.titulos-premios', [
])
	.config(config)

	.controller('viewTitulosPremiosController', function (
		$scope,
		appAuthHelper,
		collectionTitulosPremios,
		toastrFactory,
		$routeParams
	) {

		$scope.collectionTitulosPremios = collectionTitulosPremios;

		const fieldName = $routeParams.fieldName;
		const fieldValue = $routeParams.fieldValue;

		const startSnapshot = termo =>{
			var attrFilter = {
				filter: [
					{ field: fieldName, operator: "==", value: fieldValue }
				]
			};

			if (termo) {
				attrFilter.filter = `keywords array-contains ${termo}`;
			} else {
				attrFilter.limit = 60;
				toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
			}

			$scope.collectionTitulosPremios.collection.startSnapshot(attrFilter);
		}

		$scope.filter = {
			run: function (termo) {
				startSnapshot(termo);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionTitulosPremios.collection.destroySnapshot();
		});


	});


export default ngModule;
