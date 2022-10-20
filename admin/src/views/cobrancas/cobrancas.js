'use strict';

import config from './cobrancas.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.cobrancas', [
	directiveEdit.name
])
	.config(config)

	.controller('viewCobrancasController', function (
		$scope,
		$routeParams,
		appAuthHelper,
		navbarTopLeftFactory,
		collectionCobrancas,
		collectionClientes,
		cobrancasEditFactory,
		toastrFactory
	) {

		$scope.user = null;
		$scope.collectionCobrancas = collectionCobrancas;
		$scope.idCliente = $routeParams.idCliente;
		$scope.cliente = null;

		$scope.edit = function (e) {
			cobrancasEditFactory.edit(e, $scope.cliente);
		}

		const showMenu = function () {

			var menu = [{
				label: 'Adicionar Cobrança',
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
					attrFilter.limit = 10;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionCobrancas.collection.startSnapshot(attrFilter);

			}

		}

		appAuthHelper.ready()
			.then(_ => {

				$scope.user = appAuthHelper.user;

				showMenu();

				if ($scope.idCliente) {

					var filter = {
						idEmpresa: $scope.user.idEmpresa,
						idCliente: $scope.idCliente || null
					};

					$scope.collectionCobrancas.collection.getSnapshot(filter, {
						loadReferences: ['idCliente_reference', 'idPlano_reference']
					});

					collectionClientes.collection.getDoc($scope.idCliente).then(cliente => {
						if (cliente.idEmpresa == $scope.user.idEmpresa) {
							$scope.cliente = cliente;
						} else {
							window.location.href = '#!/cobrancas/';
						}
					})

				}

			})

		$scope.$on('$destroy', function () {
			$scope.collectionCobrancas.collection.destroySnapshot();
		});


	});


export default ngModule;
