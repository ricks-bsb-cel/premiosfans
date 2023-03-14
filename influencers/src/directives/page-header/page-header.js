import { noConflict } from "lodash";

const ngModule = angular.module('directives.page-header', [])

	.factory('pageHeaderFactory',
		function () {

			const _none = 0;
			const _login = 1;
			const _full = 2;
			const _light = 3;

			let modo = _none;
			let titulo = 'Voltar';
			let pageTitleClass = 'p-1 mt-3';

			const setModeNone = _ => {
				modo = _none;
				pageTitleClass = null;
			}

			const setModeLogin = _ => {
				modo = _login;
				pageTitleClass = 'mt-3';
			}

			const setModeFull = _ => {
				modo = _full;
				pageTitleClass = 'mt-3';
			}

			const setModeLight = (t, b) => {
				modo = _light;
				titulo = t || 'Voltar';
				pageTitleClass = 'pb-1 mt-3';
			}

			return {
				
				setModeNone: setModeNone,
				setModeLogin: setModeLogin,
				setModeFull: setModeFull,
				setModeLight: setModeLight,

				none: _none,
				login: _login,
				full: _full,
				light: _light,

				get modo() {
					return modo;
				},

				get titulo() {
					return titulo;
				},

				get pageTitleClass() {
					return pageTitleClass;
				}
			}

		}
	)

	.controller('pageHeaderController',
		function (
			$scope,
			appAuthHelper,
			pageHeaderFactory
		) {

			$scope.ready = false;
			$scope.currentUser = null;

			$scope.titulo = _ => {
				return pageHeaderFactory.titulo;
			}

			$scope.nome = _ => {
				return appAuthHelper.currentUser.displayName;
			}

			$scope.noneMode = _ => {
				return pageHeaderFactory.modo === pageHeaderFactory.none;
			}

			$scope.loginMode = _ => {
				return pageHeaderFactory.modo === pageHeaderFactory.login;
			}

			$scope.fullMode = _ => {
				return pageHeaderFactory.modo === pageHeaderFactory.full;
			}

			$scope.lightMode = _ => {
				return pageHeaderFactory.modo === pageHeaderFactory.light;
			}

			$scope.pageTitleClass = _ => {
				return pageHeaderFactory.pageTitleClass;
			}

			appAuthHelper.ready()
				.then(currentUser => {
					$scope.currentUser = currentUser;
					$scope.ready = true;
				})
				.catch(e => {
					console.error(e);
				})

		}
	)

	.directive('pageHeader', function () {
		return {
			restrict: 'E',
			templateUrl: 'page-header/page-header.html',
			controller: 'pageHeaderController'
		};
	});

export default ngModule;
