'use strict';

const ngModule = angular
	.module('directives.money-mask', [])
	.directive('moneyMask',
		function ($filter) {
			return {
				require: 'ngModel',
				controller: function ($scope) {
				},
				link: function link(scope, element, attrs, ngModelCtrl) {
					let
						display,
						cents;

					ngModelCtrl.$render = function () {
						display = $filter('number')(cents / 100, 2);

						if (attrs.moneyMaskPrepend) {
							display = attrs.moneyMaskPrepend + ' ' + display;
						}

						if (attrs.moneyMaskAppend) {
							display = display + ' ' + attrs.moneyMaskAppend;
						}

						element.val(display);
					}

					scope.$watch('model', function onModelChange(newValue) {
						newValue = parseFloat(newValue) || 0;

						if (newValue !== cents) {
							cents = Math.round(newValue * 100);
						}

						ngModelCtrl.$viewValue = newValue;
						ngModelCtrl.$render();
					});

					if (!attrs.$attr.readonly) {

						// Apenas para o BackSpace
						element.on('keydown', function (e) {

							if ((e.which || e.keyCode) === 8) {
								cents = parseInt(cents.toString().slice(0, -1)) || 0;

								ngModelCtrl.$setViewValue(cents / 100);
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
								cents = parseInt(cents + char);
							} else {
								return false;
							}

							var target = e.target || e.srcElement;

							if (target.selectionEnd != target.selectionStart) {
								ngModelCtrl.$setViewValue(parseInt(char) / 100);
							}
							else {
								ngModelCtrl.$setViewValue(cents / 100);
							}

							ngModelCtrl.$render();

							scope.$apply();
						})
					}
				},
				restrict: 'A',
				scope: {
					model: '=ngModel'
				}
			}
		}
	);

export default ngModule;


