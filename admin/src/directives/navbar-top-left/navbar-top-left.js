'use strict';

import angular from "angular";

// import angular from "angular";

const ngModule = angular.module('directives.navbar-top-left', [])

	.factory('navbarTopLeftFactory',
		function (
			navbarSearchFactory,
			$window,
			$timeout
		) {

			var options = [];
			var delegate = {};

			var reset = function () {
				options = [];
				navbarSearchFactory.setEnabled(false);
				updateMenu();
			};

			var extend = function (ext) {

				var opt = angular.copy(options);

				if (_.isArray(ext)) {
					ext.forEach(e => {
						if (opt.findIndex(f => { return f.label === e.label; }) < 0) {
							opt.push(e);
						}
					})
				} else {
					if (opt.findIndex(f => { return f.label === ext.label; }) < 0) {
						opt.push(ext);
					}
				}

				$timeout(_ => {
					options = opt;
					updateMenu();
				}, 500);

				return true;
			}

			var onSearch = function (cb) {
				navbarSearchFactory.setEnabled(true);
				navbarSearchFactory.onSearch(function (value) {
					cb(value);
				})
			}

			var back = function () {
				$window.history.back();
			}

			var updateMenu = function () {
				if (delegate && typeof delegate.updateMenu === 'function') {
					delegate.updateMenu(options);
				}
			}

			return {
				delegate: delegate,
				updateMenu: updateMenu,
				reset: reset,
				extend: extend,
				onSearch: onSearch,
				back: back
			};

		}
	)

	.controller('navbarTopLeftController',
		function (
			$scope,
			navbarTopLeftFactory,
			$timeout
		) {

			$scope.options = [];

			navbarTopLeftFactory.delegate.updateMenu = function (options) {
				$scope.options = options;
			}

			$scope.$on('$locationChangeStart', _ => {
				navbarTopLeftFactory.reset();
			});

			$timeout(_ => {
				navbarTopLeftFactory.updateMenu();
			})
		}
	)

	.directive('navbarTopLeft', function () {
		return {
			restrict: 'E',
			templateUrl: 'navbar-top-left/navbar-top-left.html',
			controller: 'navbarTopLeftController'
		};
	});

export default ngModule;
