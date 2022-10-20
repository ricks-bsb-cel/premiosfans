'use strict';

import config from './contratos.config';
// import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.contratos', [
	// directiveEdit.name
])
	.config(config)

	.controller('viewContratosController', function (
		$scope,
		$routeParams,
		navbarTopLeftFactory,
		collectionContratos,
		appAuthHelper,
		toastrFactory
	) {

		$scope.collectionContratos = collectionContratos;
		$scope.idCliente = $routeParams.idCliente;

		let lastTermo, showAll = false;

		const showMenu = function () {

			var menu = [
				{
					label: 'Novo Contrato',
					route: '/contratos-edit/new',
					icon: 'fas fa-plus'
				},
				{
					label: 'Exibir Revisados',
					onClick: function () {
						showAll = !showAll;
						$scope.filter.run(lastTermo);
					},
					icon: 'fas fa-archive'
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

				$scope.collectionContratos.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {

				$scope.user = appAuthHelper.profile.user;

				showMenu();

				/*
				if ($scope.idCliente) {

					var filter = {
						idEmpresa: $scope.user.idEmpresa,
						idCliente: $scope.idCliente
					};

					$scope.collectionContratos.collection.getSnapshot(filter, {
						loadReferences: ['idCliente_reference', 'idPlano_reference']
					});

					collectionContratos.collection.getDoc($scope.idCliente)
						.then(cliente => {
							if (cliente.idEmpresa == $scope.user.idEmpresa) {
								$scope.cliente = cliente;
							} else {
								window.location.href = '#!/contratos/';
							}
						})	
				}
				*/

			})

		$scope.$on('$destroy', function () {
			$scope.collectionContratos.collection.destroySnapshot();
		});

	});


export default ngModule;
