'use strict';

import config from './produtos.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.produtos', [
	directiveEdit.name
])
	.config(config)

	.controller('viewProdutosController', function (
		$scope,
		navbarTopLeftFactory,
		collectionProdutos,
		appAuthHelper,
		produtosEditFactory,
		toastrFactory
	) {

		$scope.user;
		$scope.collectionProdutos = collectionProdutos;

		$scope.edit = function (e) {
			produtosEditFactory.edit(e);
		}

		const showMenu = _ => {
			let menu = [
				{
					label: 'Novo Produto ou Serviço',
					onClick: function () { $scope.edit(null); },
					icon: 'fas fa-plus'
				}
			];

			navbarTopLeftFactory.extend(menu);
		}

		$scope.filter = {
			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.orderBy = "nome";
					attrFilter.limit = 20;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionProdutos.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.user;
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionProdutos.collection.destroySnapshot();
		});

	});


export default ngModule;
