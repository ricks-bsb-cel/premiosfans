'use strict';

const ngModule = angular.module('directives.menu-sidebar-home', [])

	.controller('menuSidebarHomeController',
		function (
			$scope,
			appAuthHelper,
			alertFactory
		) {

			$scope.currentUser = null;
			$scope.appAuthHelper = appAuthHelper;

			$scope.isAccountValid = function () {
				return $scope.currentUser &&
					!$scope.currentUser.isAnonymous &&
					$scope.currentUser.customData &&
					$scope.currentUser.customData.accountSubmitted;
			}

			$scope.acesseSuaConta = _ => {
				return !$scope.currentUser;
			}

			const body = angular.element(document.body);
			const themeSwitch = angular.element(document.getElementById('theme-mode-switch'));

			appAuthHelper.ready()

				.then(currentUser => {
					$scope.currentUser = currentUser;
				})

				.catch(e => {
					console.error(e);
				})


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

			$scope.logout = _ => {
				if (!$scope.isAccountValid()) {
					appAuthHelper.signOut();
				} else {
					alertFactory.yesno('Você terá que efetuar o acesso novamente informando CPF e Celular e receber um novo código por SMS.', 'Tem certeza que deseja encerrar sua sessão?').then(_ => {
						appAuthHelper.signOut();
					})
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
