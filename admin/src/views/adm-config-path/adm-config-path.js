'use strict';

import config from './adm-config-path.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.admConfigPath', [
	directiveEdit.name
])
	.config(config)

	.controller('viewAdmConfigPathController', function (
		$scope,
		path,
		navbarTopLeftFactory,
		collectionAdmConfigPath,
		admConfigPathEditFactory
	) {

		navbarTopLeftFactory.reset(false);
		$scope.config = path.getCurrent();

		$scope.collectionAdmConfigPath = collectionAdmConfigPath;
		// $scope.collectionAdmConfigModulos = collectionAdmConfigModulos;
		// $scope.empresas = false;
		// $scope.ready = false;

		$scope.edit = function (e) {
			admConfigPathEditFactory.edit(e);
		}

		navbarTopLeftFactory.extend({
			label: 'Novo caminho',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		$scope.$on('$destroy', function () {
			$scope.collectionAdmConfigPath.collection.destroySnapshot();
			// $scope.collectionAdmConfigPath.collection.destroy();
			// $scope.collectionAdmConfigModulos.collection.destroy();
		});


	});


export default ngModule;
