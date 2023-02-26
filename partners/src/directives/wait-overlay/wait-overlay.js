'use strict';

const ngModule = angular.module('directives.wait-overlay', [])

	.directive('waitOverlay', function () {

		return {
			restrict: 'E',
			transclude: true,
			scope: {
				ready: '='
			},
			template: `<div style="min-height:120px;" class="mr-2 ml-2" ng-class="{\'overlay-wrapper\':!ready}">
						<div ng-if="!ready" class="overlay"><i class="fas fa-3x fa-sync-alt fa-spin"></i>
						</div><ng-transclude></ng-transclude></div>`
		};

	});

export default ngModule;
