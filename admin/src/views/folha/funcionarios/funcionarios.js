'use strict';

import config from './funcionarios.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.folha.funcionarios', [
	directiveEdit.name
])
	.config(config)

	.controller('viewFolhaFuncionariosController', function (
		$scope,
		navbarTopLeftFactory,
		collectionFuncionarios,
		funcionariosEditFactory,
		toastrFactory,
		appAuthHelper
	) {

		$scope.collectionFuncionarios = collectionFuncionarios;

		$scope.user = null;

		$scope.edit = function (e) {
			funcionariosEditFactory.edit(e);
		}

		const showMenu = function () {

			var menu = [{
				label: 'Adicionar Funcionário',
				onClick: function () {
					$scope.edit(null);
				},
				icon: 'fas fa-plus'
			}];

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

				$scope.collectionFuncionarios.collection.startSnapshot(attrFilter);

			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionFuncionarios.collection.destroySnapshot();
		});

	});


export default ngModule;
