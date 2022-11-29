'use strict';

import config from './contas.config';

const ngModule = angular.module('views.contas', [
])
	.config(config)

	.controller('viewContasController', function (
		$scope,
		navbarTopLeftFactory,
		collectionContas,
		appAuthHelper,
		toastrFactory
	) {

		$scope.collectionContas = collectionContas;

		let lastTermo;

		const showMenu = function () {
			var menu = [
				{
					label: 'Nova Conta',
					route: '/contas-edit/new',
					icon: 'fas fa-plus'
				}
			];

			navbarTopLeftFactory.extend(menu);
		}

		$scope.filter = {
			run: function (termo) {

				lastTermo = termo;

				var attrFilter = { filter: [] };

				if (termo) {
					attrFilter.filter.push({ field: 'keywords', operator: 'array-contains', value: termo });
				} else {
					attrFilter.limit = 20;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionContas.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;

				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionContas.collection.destroySnapshot();
		});

	});


export default ngModule;
