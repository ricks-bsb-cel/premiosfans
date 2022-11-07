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
		toastrFactory
	) {

		$scope.collectionAppLinks = collectionAppLinks;

		const showMenu = function () {
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
