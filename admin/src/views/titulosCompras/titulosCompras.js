'use strict';

import config from './titulosCompras.config';

const ngModule = angular.module('views.titulos-compras', [
])
	.config(config)

	.controller('viewTitulosComprasController', function (
		$scope,
		appAuthHelper,
		collectionTitulosCompras,
		toastrFactory,
		$routeParams
	) {


		$scope.collectionTitulosCompras = collectionTitulosCompras;

		$scope.filter = {
			run: function (termo) {
				var attrFilter = {
					filter: [
						{ field: "idCampanha", operator: "==", value: $routeParams.idCampanha }
					]
				};

				if (termo) {
					attrFilter.filter.push({ field: "keywords", operator: "array-contains ", value: termo });
				} else {
					attrFilter.limit = 60;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionTitulosCompras.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionTitulosCompras.collection.destroySnapshot();
		});


	});


export default ngModule;
