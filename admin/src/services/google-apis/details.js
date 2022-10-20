
'use strict';

const ngModule = angular.module('services.google-apis.details', [])

	.factory('googleDetails',
		function (
			$http,
			URLs
		) {

			var getAddressComponent = function (place, resultType, type1, type2) {

				var result = null;

				if (!place || !place.address_components) { return result; }

				place.address_components.forEach(function (ac) {
					if (!result && ac.types.includes(type1) && (!type2 || ac.types.includes(type2))) {
						result = ac[resultType];
					}
				})

				return result;

			}

			var get = function (attrs) {

				$http({
					url: URLs.google.details,
					method: 'post',
					data: {
						place_id: attrs.place_id
					}
				}).then(
					function (response) {
						if (typeof attrs.success == 'function') {

							var result = response.data.data.result;

							result.place_id = attrs.place_id;
							result._uf = getAddressComponent(result, 'short_name', 'administrative_area_level_1', 'political');
							result._cidade = getAddressComponent(result, 'short_name', 'administrative_area_level_2', 'political');

							attrs.success(result);
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
				get: get
			};

			return service;
		}
	);

export default ngModule;
