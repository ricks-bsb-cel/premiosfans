'use strict';

let ngModule;

(function () {

	ngModule = angular.module('factories.pexels', [])

		.factory('pexelsFactory',

			function (
				$http,
				pexelsConfig,
				$q
			) {

				var searchImage = function (query, orientation) {
					if (!query) { return; }

					var options = {
						url:
							query.startsWith('https') ?
								query + '&locale=pt-BR' :
								pexelsConfig.urls.search +
								'?query=' + query +
								'&per_page=' + pexelsConfig.itemsPerLoad +
								'&page=1' +
								(orientation ? '&orientation=' + orientation : '') +
								'&locale=pt-BR',
						method: 'GET',
						responseType: 'json',
						headers: {
							'Authorization': pexelsConfig.apikey,
						}
					};

					return $q(function (resolve, reject) {
						$http(options).then(function success(response) {
							resolve(response.data);
						}, function error(e) {
							reject(e);
						});

					})
				};

				var factory = {
					searchImage: searchImage
				};

				return factory;
			}
		);

})();

export default ngModule;
