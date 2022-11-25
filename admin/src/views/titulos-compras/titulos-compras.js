'use strict';

import config from './titulos-compras.config';
import directivesError from './directives/errors/errors';

const ngModule = angular.module('views.titulos-compras', [
	directivesError.name
])
	.config(config)

	.controller('viewTitulosComprasController', function (
		$scope,
		appAuthHelper,
		collectionTitulosCompras,
		toastrFactory,
		$routeParams,
		titulosComprasErrorsFactory,
		premiosFansService
	) {

		$scope.collectionTitulosCompras = collectionTitulosCompras;
		$scope.idCampanha = $routeParams.idCampanha || null;

		const startSnapshot = termo => {
			var attrFilter = { filter: [] };

			if ($scope.idCampanha) {
				attrFilter.filter.push({ field: "idCampanha", operator: "==", value: $scope.idCampanha });
			}

			if (termo) {
				attrFilter.filter.push({ field: "keywords", operator: "array-contains", value: termo });
			} else {
				attrFilter.limit = 60;
				toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
			}

			$scope.collectionTitulosCompras.collection.startSnapshot(attrFilter);
		}

		$scope.pagar = tituloCompra => {
			premiosFansService.pagarTituloCompra({
				idTituloCompra: tituloCompra.id
			})
		}

		$scope.percent = (max, qtd) => {
			return Math.floor((qtd / max) * 100) + '%';
		}

		$scope.verificar = tituloCompra => {
			premiosFansService.checkTituloCompra({
				idTituloCompra: tituloCompra.id
			})
		}

		$scope.filter = {
			run: function (termo) {
				startSnapshot(termo);
			}
		}

		$scope.showErrors = doc => {
			titulosComprasErrorsFactory.show(doc);
		}

		appAuthHelper.ready()
			.then(_ => {
				startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionTitulosCompras.collection.destroySnapshot();
		});


	});


export default ngModule;
