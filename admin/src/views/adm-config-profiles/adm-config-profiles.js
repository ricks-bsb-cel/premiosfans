'use strict';

import config from './adm-config-profiles.config';

let ngModule = angular.module('views.adm-config-profiles', [
])
	.config(config)

	.controller('viewAdmConfigProfilesController', function (
		$scope,
		path,
		$location,
		navbarTopLeftFactory,
		collectionAdmConfigProfiles
	) {

		$scope.config = path.getCurrent();

		$scope.collectionAdmConfigProfiles = collectionAdmConfigProfiles;
		$scope.user = null;

		$scope.edit = function (profile) {
			profile = profile || {};
			$location.path('/adm-config-profile-edit/' + (profile.id || 'new'));
		}

		navbarTopLeftFactory.extend({
			label: 'Novo Perfil',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		/*
		firebaseService.getProfile(userProfile => {
			$scope.user = userProfile.user;
			$scope.collectionAdmConfigProfiles.collection.getSnapshot();
		})
		*/

		/*
		firebaseService.registerListenersAuthStateChanged(function (user, adm) {
			if (user) {
				$scope.user = user;
				$scope.collectionAdmConfigProfiles.collection.getSnapshot();
			}
		})
		*/

		// firebaseService.init();

		$scope.$on('$destroy', function () {
			// $scope.collectionAdmConfigProfiles.collection.destroy();
		});

	});


export default ngModule;
