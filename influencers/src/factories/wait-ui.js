'use strict';

let ngModule = angular.module('factories.wait.ui', [
])
	.factory('waitUiFactory',
		function (
		) {

			const waitElement = document.getElementById('wait');

			const show = _ => {
				waitElement.classList.add('visible');
			};

			const hide = function () {
				waitElement.classList.remove('visible');
			}

			return {
				start: show,
				show: show,
				hide: hide,
				stop: hide
			};

		}
	);

export default ngModule;
