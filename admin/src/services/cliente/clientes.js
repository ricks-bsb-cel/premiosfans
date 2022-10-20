'use strict';

const ngModule = angular.module('services.clienteService', [])

	.factory('clienteService',
		function (
			$http,
			URLs
		) {

			/*
			const checkLogin = function (attrs) {

				$http({
					url: URLs.clientes.checkLogin,
					method: 'post',
					data: attrs.data
				}).then(
					function (response) {
						if (typeof attrs.success == 'function') {
							attrs.success(response.data);
						}
					},
					function (e) {
						if (typeof attrs.error == 'function') {
							console.error(e);
							attrs.error(e);
						}
					}
				);

			};

			const updateUserStats = function (attrs) {

				$http({
					url: URLs.clientes.updateUserStats,
					method: 'post',
					headers: {
						token: firebaseService.getUserToken()
					}
				}).then(
					function (response) {
						if (typeof attrs.success === 'function') {
							attrs.success(response.data);
						}
					},
					function (e) {
						if (typeof attrs.error === 'function') {
							console.error(e);
							attrs.error(e);
						}
					}
				);

			};
			*/

			const fakeData = function (attrs) {

				$http({
					url: URLs.clientes.fakeData,
					method: 'get'
				}).then(
					function (response) {
						if (typeof attrs.success === 'function') {
							attrs.success(response.data.results[0]);
						}
					},
					function (e) {
						if (typeof attrs.error === 'function') {
							console.error(e);
							attrs.error(e);
						}
					}
				);

			};

			return {
				fakeData: fakeData
			};
		}
	);

export default ngModule;
