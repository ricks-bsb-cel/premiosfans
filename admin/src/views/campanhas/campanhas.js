'use strict';

import config from './campanhas.config';

const ngModule = angular.module('views.campanhas', [
])
	.config(config)

	.controller('viewCampanhasController', function (
		$scope,
		navbarTopLeftFactory,
		collectionCampanhas,
		appAuthHelper,
		toastrFactory
	) {

		$scope.collectionCampanhas = collectionCampanhas;

		let lastTermo, showAll = false;

		const showMenu = function () {

			var menu = [
				{
					label: 'Nova Campanha',
					route: '/campanhas-edit/new',
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

				if (!showAll) attrFilter.filter.push({ field: 'situacao', operator: '==', value: 'ativo' });

				$scope.collectionCampanhas.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;

				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionCampanhas.collection.destroySnapshot();
		});

	});


export default ngModule;
