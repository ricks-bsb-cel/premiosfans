'use strict';

const ngModule = angular.module('directives.menu-sidebar-home', [])

	.controller('menuSidebarHomeController',
		function (
			$scope,
			appAuthHelper
		) {

			$scope.appAuthHelper = appAuthHelper;

			const body = angular.element(document.body);
			const themeSwitch = angular.element(document.getElementById('theme-mode-switch'));

			$scope.bindMenuOptions = _ => {
				if (body.hasClass('theme-light')) {
					themeSwitch.attr('checked', false);
				} else {
					themeSwitch.attr('checked', true);
				}
			}

			const setThemeLight = _ => {
				body.removeClass('theme-dark').addClass('theme-light');
				themeSwitch.attr('checked', false);
				window.localStorage.currentTheme = 'light';
			}

			const setThemeDark = _ => {
				body.removeClass('theme-light').addClass('theme-dark');
				themeSwitch.attr('checked', true);
				window.localStorage.currentTheme = 'dark';
			}

			$scope.changeTheme = _ => {
				if (body.hasClass('theme-light')) {
					setThemeDark();
				} else {
					setThemeLight();
				}
			}
		}
	)

	.directive('menuSidebarHome', function () {
		return {
			restrict: 'E',
			templateUrl: 'menu-sidebar-home/menu-sidebar-home.html',
			controller: 'menuSidebarHomeController',
			link: function (scope) {
				scope.bindMenuOptions();
			}
		};
	});

export default ngModule;
