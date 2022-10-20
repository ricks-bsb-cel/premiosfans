'use strict';

import Swal from 'sweetalert2'

let ngModule = angular.module('factories.block.ui', [])

	.factory('blockUiFactory',
		function (
			$timeout
		) {

			let currentSwal = null;
			let currentPercent = 0;

			const start = callback => {
				currentSwal = Swal.fire({
					timerProgressBar: true,
					customClass: {
						container: 'block-ui'
					},
					didOpen: function () {
						Swal.showLoading();
						if (typeof callback === 'function') {
							$timeout(_ => {
								callback();
							}, 100)
						}
					},
					willClose: function () {
						currentSwal = null;
					}
				})
			};

			const percentStart = _ => {
				currentPercent = 0;
				document.getElementById("percent-center").innerHTML = '0%';
				document.getElementById("percent-center").style.display = "initial";
			}

			const percentStop = _ => {
				currentPercent = 0
				document.getElementById("percent-center").innerHTML = '0%';
				document.getElementById("percent-center").style.display = "none";
			}

			const percent = function (value, max) {

				const v = Math.round(max ? Math.round((value * 100.0) / max) : value);

				if (v <= currentPercent) {
					return;
				}

				currentPercent = v;
				let innerHtml = v.toString() + '%';

				if (document.getElementById("percent-center").innerHTML !== innerHtml) {
					document.getElementById("percent-center").innerHTML = innerHtml;
				}

			}

			const stop = function () {
				if (currentSwal) {
					currentSwal.close();
				}
				percentStop();
			}

			const factory = {
				start: start,
				stop: stop,
				percent: percent,
				percentStart: percentStart,
				percentStop: percentStop
			};

			return factory;
		}
	);

export default ngModule;
