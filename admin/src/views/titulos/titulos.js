'use strict';

import config from './titulos.config';

const ngModule = angular.module('views.titulos', [
])
	.config(config)

	.controller('viewTitulosController', function (
		$scope,
		appAuthHelper,
		collectionTitulos,
		toastrFactory,
		$routeParams
	) {

		$scope.collectionTitulos = collectionTitulos;

		$scope.filter = {

			run: function (termo) {

				var attrFilter = {
					filter: []
				};

				if ($routeParams.idCampanha) {
					attrFilter.filter.push({ field: "idCampanha", operator: "==", value: $routeParams.idCampanha });
				}

				if (termo) {
					attrFilter.filter.push({ field: "keywords", operator: "array-contains", value: termo });
				} else {
					attrFilter.limit = 120;
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
