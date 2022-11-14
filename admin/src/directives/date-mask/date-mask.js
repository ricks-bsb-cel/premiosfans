'use strict';

const ngModule = angular
	.module('directives.date-mask', [])
	.directive('dateMask',
		function (appFirestoreHelper) {
			return {
				require: 'ngModel',
				controller: function ($scope, appConfig, $timeout) {

					$scope.applyMask = e => {
						$timeout(_ => {
							VMasker(e).maskPattern("99/99/9999");
						})
					}

				},
				link: function link(scope, element, attrs, ngModelCtrl) {
					var value,
						fieldName = ngModelCtrl.$$attr.ngModel.split('.').slice(-1)[0];

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
							scope.parentModel[fieldName] = d.format('DD/MM/YYYY');
							scope.parentModel[fieldName + '_yyyymmdd'] = d.format('YYYY-MM-DD');
							scope.parentModel[fieldName + '_timestamp'] = appFirestoreHelper.toTimestamp(d.toDate());

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
					model: '=ngModel',
					parentModel: '='
				}
			}
		}
	);

export default ngModule;

