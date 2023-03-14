'use strict';

import Swal from 'sweetalert2'

let ngModule = angular.module('factories.block.ui', [])

	.factory('waitUiFactory',
		function (
		) {

			var currentSwal = null;

			var start = function () {

				if (currentSwal !== null) {
					return;
				}

				currentSwal = Swal.fire({
					timerProgressBar: true,
					allowOutsideClick: false,
					allowEscapeKey: false,
					customClass: {
						container: 'block-ui'
					},
					didOpen: function () {
						Swal.showLoading()
					},
					willClose: function () {
						currentSwal = null;
					}
				})

			};

			var stop = function () {
				if (currentSwal) {
					currentSwal.close();
					currentSwal = null;
				}
			}

			var factory = {
				start: start,
				stop: stop
			};

			return factory;
		}
	);

export default ngModule;
