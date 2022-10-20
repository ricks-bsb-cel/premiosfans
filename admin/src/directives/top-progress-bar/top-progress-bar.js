'use strict';

const ngModule = angular.module('directives.top-progress-bar', [])

	.factory('topProgressBarFactory',
		function (
		) {

			let element,
				config;

			const init = e => {
				element = e;

				config = {
					element: element.find('.top-progress.progress'),
					elementProgress: element.find('.top-progress.progress .progress-bar'),
					elementSrOnly: element.find('.top-progress.progress .sr-only')
				};
			}

			const show = function () {
				config.elementProgress.attr('arial-valuenow', '0');
				config.elementProgress.css('width', '0')
				config.elementSrOnly.html('0%');
				config.element.show();
			}

			const hide = function () {
				config.element.hide();
				config.elementProgress.attr('arial-valuenow', '0');
				config.elementProgress.css('width', '0')
				config.elementSrOnly.html('0%');
			}

			const set = function (value, max) {

				if (max) {
					value = Math.round((value * 100.0) / max);
				}

				value = Math.round(value);

				console.info(value);

				config.elementProgress.attr('arial-valuenow', value);
				config.elementProgress.css('width', value + '%')
				config.elementSrOnly.html(value + '%');
			}

			return {
				show: show,
				hide: hide,
				set: set,
				config: config,
				init: init
			};

		})

	.controller('topProgressBarController',
		function (
			$scope,
			topProgressBarFactory
		) {
			$scope.topProgressBarFactory = topProgressBarFactory;
		}
	)

	.directive('topProgressBar', function () {
		return {
			restrict: 'E',
			templateUrl: 'top-progress-bar/top-progress-bar.html',
			controller: 'topProgressBarController',
			link: function (scope, element) {
				scope.topProgressBarFactory.init(element);
			}
		};
	});

export default ngModule;
