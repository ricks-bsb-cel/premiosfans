'use strict';

import config from './empresas.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.empresas', [
	directiveEdit.name
])
	.config(config)

	.controller('viewEmpresasController', function (
		$scope,
		appAuthHelper,
		collectionEmpresas,
		empresasEditFactory
	) {

		$scope.collectionEmpresas = collectionEmpresas;
		$scope.isSuperUser = false;

		$scope.edit = function (e) {
			empresasEditFactory.edit(e);
		}

		$scope.filter = {
			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				}

				$scope.collectionEmpresas.collection.startSnapshot(attrFilter);

			}
		}

		/*
		navbarTopLeftFactory.extend({
			label: 'Nova Empresa',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});
		*/

		appAuthHelper.ready()
			.then(_ => {
				$scope.isSuperUser = appAuthHelper.profile.user.superUser;

				if (!$scope.isSuperUser) {
					$scope.collectionEmpresas.collection.startSnapshot({
						id:appAuthHelper.profile.user.idEmpresa
					});
				}

			})




		/*
		firebaseService.registerListenersAuthStateChanged(profile => {
			if (profile.user) {

				$scope.user = profile.user;

				if ($scope.user.superUser) {
					$scope.collectionEmpresas.collection.getSnapshot();
				} else {
					$scope.collectionEmpresas.loadEmpresas(user);
				}
			}
		})

		firebaseService.init();
		*/

		$scope.$on('$destroy', function () {
			$scope.collectionEmpresas.collection.destroySnapshot();
		});

	});


export default ngModule;
