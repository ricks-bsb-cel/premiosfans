'use strict';

import config from './faq.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.faq', [
	directiveEdit.name
])
	.config(config)

	.controller('viewFaqController', function (
		$scope,
		navbarTopLeftFactory,
		collectionFaq,
		appAuthHelper,
		toastrFactory,
		faqEditFactory
	) {
		$scope.collectionFaq = collectionFaq;

		let lastTermo;

		$scope.edit = function (e) {
			faqEditFactory.edit(e);
		}

		const showMenu = _ => {

			let menu = [
				{
					label: 'Novo Registro',
					onClick: function () { $scope.edit(null); },
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

				$scope.collectionFaq.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionFaq.collection.destroySnapshot();
		});

	});


export default ngModule;
