'use strict';

const _footerBarHide = 0;
const _footerBarShow = 1;

const ngModule = angular.module('directives.footer-bar', [])

	.factory('footerBarFactory',
		function () {

			const e = angular.element(document.getElementById("footer-bar"));;
			let modo = _footerBarHide;

			const setModeHide = _ => {
				e.css('display', 'none');
				modo = _footerBarHide;
			}

			const setModeShow = _ => {
				e.css('display', 'initial');
				modo = _footerBarShow;
			}

			return {
				hide: setModeHide,
				show: setModeShow,

				get modo() {
					return modo;
				}

			}

		}
	)

	.controller('footerBarController',
		function (
			$scope,
			footerBarFactory
		) {

			$scope.showMode = _ => {
				return footerBarFactory.modo === _footerBarShow;
			}

			$scope.hideMode = _ => {
				return footerBarFactory.modo === _footerBarHide;
			}

		}
	)

	.directive('footerBar', function () {
		return {
			restrict: 'E',
			templateUrl: 'footer-bar/footer-bar.html',
			controller: 'footerBarController'
		};
	});

export default ngModule;
