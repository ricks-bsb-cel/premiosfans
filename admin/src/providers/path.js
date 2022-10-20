'use strict';

let ngModule;

ngModule = angular.module('providers.path', [])
	.provider('path',
		function (
		) {

			var
				rootScope,
				paths = {},
				self = this;

			self.currentKey = null;

			self.get = function (view) {
				return paths[view];
			};

			self.addPath = function (view, object) {
				paths[view] = object;
				return paths[view];
			};

			self.getPath = function (view) {
				return paths[view].path;
			};

			self.getIcon = function (view) {
				return paths[view].icon;
			};

			self.getLabel = function (view) {
				return paths[view].label;
			};

			self.getCurrent = function () {
				let result = {};
				let currentViewName = `/${self.getCurrentViewName()}/`;
				
				Object.keys(paths).forEach(k => {
					if (currentViewName.startsWith(paths[k].path)) {
						result = paths[k];
					}
				})

				return result;
			};

			self.getCurrentViewName = function () {
				let result = window.location.hash.substring(3);

				if (result.slice(-1) === '/') {
					result = result.slice(0, -1);
				}

				return result;
			};

			self.getAllPaths = function () {
				return paths;
			}

			self.setCurrent = function (view) {
				self.currentKey = view || 'home';

				if (rootScope.mainController.setViewAttribute) {
					rootScope.mainController.setViewAttribute();
				}
			};

			self.createBackUrl = function (view, parm1, parm2, parm3, parm4) {
				var url = self.get(view).path;

				if (parm1) { url += parm1; }
				if (parm2) { url += '/' + parm2; }
				if (parm3) { url += '/' + parm3; }
				if (parm4) { url += '/' + parm4; }

				return btoa(url);
			}

			self.getBackUrl = function (base64) {
				return base64 ? atob(base64) : null;
			}

			self.$get = function (
				$rootScope
			) {

				rootScope = $rootScope;

				self.hasPermission = function (view) {
					if (paths[view].permissions) {
						return true;
					} else {
						return true;
					}
				};

				return self;
			};

			if (!window.location.hash) {
				if (window.location.pathname.startsWith('/adm/home')) {
					const first = $("aside.main-sidebar .sidebar .nav li.nav-item:first a").attr('href');
					window.location.href = first;
				}
			}

		});

export default ngModule;
