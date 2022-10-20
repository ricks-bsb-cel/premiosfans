'use strict';

import config from './messagesReceived.config';

var ngModule;

ngModule = angular.module('views.messagesReceived', [])
	.config(config)

	.controller('viewMessagesReceivedController', function (
		$scope,
		navbarTopLeftFactory,
		collectionWebhook,
		firebaseService
	) {

		navbarTopLeftFactory.reset(false);

		$scope.collectionWebhook = collectionWebhook;

		$scope.user = null;

		firebaseService.getProfile(userProfile => {
			$scope.user = userProfile.user;

			collectionWebhook.collection.getSnapshot({
				_evento: 'received'
			}, {
				limit: 50
			});
		})

		/*
		firebaseService.registerListenersAuthStateChanged(user => {
			if (user) {

				$scope.user = user;

				collectionWebhook.collection.getSnapshot({
					_evento: 'received'
				}, {
					limit: 50
				});

			}
		})
		*/

		firebaseService.init();

		$scope.$on('$destroy', function () {
			$scope.collectionWebhook.collection.destroy();
		});


	});


export default ngModule;
