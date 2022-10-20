'use strict';

import config from './transacoes.config';

const ngModule = angular.module('views.transacoes', [
])
	.config(config)

	.controller('viewTransacoesController', function (
		$scope,
		collectionTransacoes,
		appAuthHelper,
		toastrFactory,
		navbarTopLeftFactory,
		contasService
	) {

		$scope.user = null;
		$scope.collectionTransacoes = collectionTransacoes;

		navbarTopLeftFactory.extend([{
			label: 'Atualizar',
			onClick: function () {
				contasService.updateTransactions({
					idEmpresa: appAuthHelper.profile.user.idEmpresa
				});
			},
			icon: 'fas fa-refresh'
		}]);

		$scope.filter = {
			run: function (termo) {
				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.limit = 20;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionTransacoes.collection.startSnapshot(attrFilter);
			}
		}

		$scope.$on('$destroy', function () {
			$scope.collectionTransacoes.collection.destroySnapshot();
		});

	});


export default ngModule;
