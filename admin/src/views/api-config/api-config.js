'use strict';

import config from './api-config.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.api-config', [
	directiveEdit.name
])
	.config(config)

	.controller('viewApiConfigController', function (
		$scope,
		navbarTopLeftFactory,
		collectionApiConfig,
		apiConfigEditFactory
	) {

		$scope.collectionApiConfig = collectionApiConfig;

		$scope.edit = function (e) {
			apiConfigEditFactory.edit(e);
		}

		navbarTopLeftFactory.extend({
			label: 'Novo Registro',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		$scope.delete = row => {
			collectionApiConfig.remove(row);
		}

		$scope.$on('$destroy', function () {
			$scope.collectionApiConfig.collection.destroySnapshot();
		});

	});


export default ngModule;
