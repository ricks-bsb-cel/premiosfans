'use strict';

const ngModule = angular.module('services.google-apis.autocomplete', [])

	.factory('googleAutocomplete',
		function (
			$http,
			URLs
		) {

			var getAddress = function (attrs) {

				$http({
					url: URLs.google.autocomplete,
					method: 'post',
					data: {
						term: attrs.term,
						types: 'address'
					}
				}).then(
					function (response) {
						if (typeof attrs.success == 'function') {
							attrs.success(response.data.data.predictions);
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

			var service = {
				getAddress: getAddress
			};

			return service;
		}
	);

export default ngModule;
