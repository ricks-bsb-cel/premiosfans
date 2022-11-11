'use strict';

const ngModule = angular
	.module('directives.date-mask', [])
	.directive('dateMask',
		function () {
			return {
				require: 'ngModel',
				controller: function ($scope, appConfig, $timeout) {

					$scope.applyMask = e => {
						$timeout(_ => {
							VMasker(e).maskPattern(appConfig.get("/masks/data/VMasker"));
						})
					}

				},
				link: function link(scope, element, attrs, ngModelCtrl) {
					var value;

					scope.applyMask(element);

					ngModelCtrl.$render = function () {
						element.val(value);

						if (!value) return;

						if (value.length !== 10) {
							ngModelCtrl.$setValidity('date-mask', false);
							return;
						};

						var d = moment(value, 'DD/MM/YYYY');

						if (d.isValid()) {
							/*
							$scope.model[scope.options.key] = d.format('YYYY-MM-DD');
							$scope.model[scope.options.key + '_ddmmyyyy'] = d.format('DD/MM/YYYY');
							$scope.model[$scope.options.key + '_timestamp'] = appFirestoreHelper.toTimestamp(d.toDate());
							*/
							ngModelCtrl.$setValidity('date-mask', true);
						} else {
							ngModelCtrl.$setValidity('date-mask', false);
						}
					}

					scope.$watch('model', function onModelChange(newValue) {
						value = newValue;

						ngModelCtrl.$viewValue = newValue;
						ngModelCtrl.$render();
					});
				},
				restrict: 'A',
				scope: {
					model: '=ngModel'
				}
			}
		}
	);

export default ngModule;


