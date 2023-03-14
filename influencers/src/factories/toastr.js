'use strict';

let ngModule;

ngModule = angular.module('factories.toastr', [])

	.config(function (toastrConfig) {
		angular.extend(toastrConfig, {
			positionClass: 'toast-bottom-right'
		});
	})

	.factory('toastrFactory',

		function (
			toastr,
			globalParms
		) {

			var success = function (msg, title) {
				toastr.success(msg, title || globalParms.appName);
			};

			var info = function (msg, title) {
				toastr.info(msg, title || globalParms.appName);
			};

			var error = function (msg, title) {
				toastr.error(msg, title || globalParms.appName);
			}

			var factory = {
				success: success,
				error: error,
				info: info
			};

			return factory;
		}
	);


export default ngModule;
