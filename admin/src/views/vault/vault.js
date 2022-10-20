'use strict';

import config from './vault.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.vault', [
	directiveEdit.name
])
	.config(config)

	.controller('viewVaultController', function (
		$scope,
		navbarTopLeftFactory,
		collectionVault,
		vaultEditFactory,
		firebaseService
	) {

		$scope.collectionVault = collectionVault;
		$scope.user = null;

		$scope.edit = function (e) {
			vaultEditFactory.edit(e);
		}

		navbarTopLeftFactory.extend({
			label: 'Novo Registro',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		firebaseService.getProfile(userProfile => {
			$scope.user = userProfile.user;
			$scope.collectionVault.collection.getSnapshot();
		})

		/*
		firebaseService.registerListenersAuthStateChanged(profile => {
			if (profile.user) {
				$scope.user = profile.user;
				$scope.collectionVault.collection.getSnapshot();
			}
		})
		*/

		firebaseService.init();

		$scope.$on('$destroy', function () {
			$scope.collectionVault.collection.destroy();
		});


	});


export default ngModule;
