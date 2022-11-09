'use strict';

import config from './app-links.config';

const ngModule = angular.module('views.app-links', [
])
	.config(config)

	.controller('viewAppLinksController', function (
		$scope,
		appAuthHelper,
		navbarTopLeftFactory,
		collectionAppLinks,
		toastrFactory,
		premiosFansService
	) {

		$scope.collectionAppLinks = collectionAppLinks;

		const generate = _ => {
			premiosFansService.generateTemplates();
		}

		const showMenu = function () {
			var menu = [
				{
					label: 'Gerar',
					onClick: generate,
					icon: 'fas fa-refresh'
				}
			];

			navbarTopLeftFactory.extend(menu);
		}

		$scope.filter = {

			run: function (termo) {

				var attrFilter = {
					loadReferences: ['campanhas_reference', 'empresas_reference']
				};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.limit = 60;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionAppLinks.collection.startSnapshot(attrFilter);

			}

		}

		appAuthHelper.ready()
			.then(_ => {
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionAppLinks.collection.destroySnapshot();
		});


	});


export default ngModule;
