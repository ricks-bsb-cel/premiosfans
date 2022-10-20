'use strict';

// https://zoepay-57t7prxj.uc.gateway.dev/api/collections/v1/get/clientes?search=con

let ngModule = angular.module('factories.collections', [])

	.factory('collectionsFactory',

		function (
			URLs
		) {

			var createRequest = attrs => {

				var url = URLs.collections;

				if (!attrs.collection || (!attrs.search && !attrs.id)) {
					throw new Error('invalid parms');
				}

				url += attrs.collection + '?';

				if (attrs.id) {
					url += 'id=' + id;
				} else {
					url += 'search=' + attrs.search;
				}

				return url;

			};

			var factory = {
				createRequest: createRequest
			};

			return factory;
		}
	);

export default ngModule;
