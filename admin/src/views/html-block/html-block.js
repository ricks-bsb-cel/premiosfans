'use strict';

import config from './html-block.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.html-block', [
	directiveEdit.name
])
	.config(config)

	.controller('viewHtmlBlockController', function (
		$scope,
		navbarTopLeftFactory,
		collectionHtmlBlock,
		appAuthHelper,
		htmlBlockEditFactory
	) {

		$scope.user;
		$scope.collectionHtmlBlock = collectionHtmlBlock;

		$scope.edit = function (e) {
			htmlBlockEditFactory.edit(e);
		}

		const showMenu = _ => {

			let menu = [
				{
					label: 'Novo HTML',
					onClick: function () { $scope.edit(null); },
					icon: 'fas fa-plus'
				}
			];

			navbarTopLeftFactory.extend(menu);

		}

		const startSnapshot = termo => {
			var attrFilter = { 
				filter: []
			};

			if (termo) {
				attrFilter.filter.push({ field: "keywords", operator: "array-contains", value: termo });
			} else {
				attrFilter.limit = 240;
				toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
			}

			$scope.collectionHtmlBlock.collection.startSnapshot(attrFilter);
		}

		$scope.clone = data => {
			data = { ...data };

			data.id = 'new';
			data.sigla += '-copy';

			delete data.$$hashKey;

			$scope.collectionHtmlBlock.save(data);
		}

		$scope.filter = {
			run: function (termo) {
				startSnapshot(termo);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.user;
				// $scope.collectionHtmlBlock.collection.startSnapshot();
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionHtmlBlock.collection.destroySnapshot();
		});

	});


export default ngModule;
