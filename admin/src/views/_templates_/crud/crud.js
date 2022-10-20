'use strict';

import config from './crud.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.crud', [
	directiveEdit.name
])
	.config(config)

	.controller('viewCrudController', function (
		$scope,
		navbarTopLeftFactory,
		collectionCrud,
		crudEditFactory
	) {

		$scope.collectionCrud = collectionCrud;

		$scope.edit = function (e) {
			crudEditFactory.edit(e);
		}

		navbarTopLeftFactory.extend({
			label: 'Novo Registro',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		$scope.delete = row => {
			collectionCrud.remove(row);
		}

		$scope.$on('$destroy', function () {
			$scope.collectionCrud.collection.destroySnapshot();
		});

	});


export default ngModule;
