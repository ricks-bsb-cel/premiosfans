'use strict';

import config from './entidades.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.entidades', [
	directiveEdit.name
])
	.config(config)

	.controller('viewEntidadesController', function (
		$scope,
		$routeParams,
		navbarTopLeftFactory,
		collectionEntidades,
		entidadesEditFactory,
		toastrFactory,
		appAuthHelper
	) {

		$scope.type = $routeParams.type;
		$scope.collectionEntidades = collectionEntidades;
		$scope.user = null;

		$scope.edit = function (e) {
			entidadesEditFactory.edit(e, $scope.type);
		}

		const showMenu = function () {
			var menu = [{
				label: 'Adicionar',
				onClick: function () {
					$scope.edit(null);
				},
				icon: 'fas fa-plus'
			}];

			navbarTopLeftFactory.extend(menu);
		}

		$scope.filter = {
			run: function (termo) {
				var attrFilter = {
					filter: [
						{ field: "idEmpresa", operator: "array-contains", value: appAuthHelper.profile.user.idEmpresa },
						{ field: `is${$scope.type}`, operator: "==", value: true }
					]
				};

				if (termo) {
					attrFilter.filter.push({
						field: "keywords",
						operator: "array-contains",
						value: termo
					});
				} else {
					attrFilter.orderBy = "nome";
					attrFilter.limit = 20;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionEntidades.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionEntidades.collection.destroySnapshot();
		});

	});


export default ngModule;
