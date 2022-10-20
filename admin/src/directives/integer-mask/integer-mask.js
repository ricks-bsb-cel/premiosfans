'use strict';

const ngModule = angular
	.module('directives.integer-mask', [])
	.directive('integerMask',
		function ($filter) {
			return {
				require: 'ngModel',
				link: function link(scope, element, attrs, ngModelCtrl) {
					var display, value;

					ngModelCtrl.$render = function () {
						display = $filter('number')(value);

						element.val(display);
					}

					scope.$watch('model', function onModelChange(newValue) {
						newValue = parseInt(newValue) || 0;

						if (newValue !== value) {
							value = Math.round(newValue);
						}

						ngModelCtrl.$viewValue = newValue;
						ngModelCtrl.$render();
					});

					element.on('keydown', function (e) {
						if ((e.which || e.keyCode) === 8) {
							value = parseInt(value.toString().slice(0, -1)) || 0;

							ngModelCtrl.$setViewValue(value);
							ngModelCtrl.$render();
							scope.$apply();
							e.preventDefault();
						}
					});

					element.on('keypress', function (e) {
						var key = e.which || e.keyCode;

						if (key === 9 || key === 13) {
							return true;
						}

						var char = String.fromCharCode(key);
						e.preventDefault();

						if (char.search(/[0-9\-]/) === 0) {
							value = parseInt(value + char);
						}
						else {
							return false;
						}

						var target = e.target || e.srcElement;

						if (target.selectionEnd != target.selectionStart) {
							ngModelCtrl.$setViewValue(parseInt(char));
						}
						else {
							ngModelCtrl.$setViewValue(value);
						}
						ngModelCtrl.$render();
						scope.$apply();
					})
				},
				restrict: 'A',
				scope: {
					model: '=ngModel'
				}
			}
		}
	);

export default ngModule;


