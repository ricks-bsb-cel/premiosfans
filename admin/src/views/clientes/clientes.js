'use strict';

import config from './clientes.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.clientes', [
	directiveEdit.name
])
	.config(config)

	.controller('viewClientesController', function (
		$scope,
		navbarTopLeftFactory,
		collectionClientes,
		clientesEditFactory,
		toastrFactory,
		appAuthHelper
	) {

		$scope.collectionClientes = collectionClientes;

		$scope.user = null;

		$scope.edit = function (e) {
			clientesEditFactory.edit(e);
		}

		const showMenu = function () {

			var menu = [{
				label: 'Novo Cliente',
				onClick: function () {
					$scope.edit(null);
				},
				icon: 'fas fa-plus'
			}];

			if ($scope.user.superUser) {

				menu.push({
					label: 'Reindex',
					onClick: function () {
						collectionClientes.reindex();
					},
					icon: 'fas fa-indent'
				})

				menu.push({
					label: 'Remover Dados de Teste',
					onClick: function () {
						debugger;
						/*
						collectionCobrancas.deleteFakeData(firebaseService.idEmpresa, true, function () {
							collectionContratos.deleteFakeData(firebaseService.idEmpresa, false, function () {
								collectionClientes.deleteFakeData(firebaseService.idEmpresa, false);
							});
						});
						*/
					},
					icon: 'fas fa-folder-minus'
				});
			}

			navbarTopLeftFactory.extend(menu);

		}

		$scope.filter = {
			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.orderBy = "nome";
					attrFilter.limit = 10;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionClientes.collection.startSnapshot(attrFilter);

			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionClientes.collection.destroySnapshot();
		});

	});


export default ngModule;
