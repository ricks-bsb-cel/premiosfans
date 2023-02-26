'use strict';

import config from './cartos-admin.config';

const ngModule = angular.module('views.cartos-admin', [
])
	.config(config)

	.controller('viewCartosAdminController', function (
		$scope,
		appAuthHelper,
		collectionCartosServiceUserCredentials
	) {

		$scope.ready = false;

		$scope.collectionCartosServiceUserCredentials = collectionCartosServiceUserCredentials;
		
		appAuthHelper.ready()
			.then(_ => {
				$scope.ready = true;
			})

		$scope.$on('$destroy', function () {
			$scope.collectionCartosServiceUserCredentials.collection.destroySnapshot();
		});
	});


export default ngModule;
