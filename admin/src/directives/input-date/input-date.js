
const ngModule = angular.module('directives.input-date', [])

	.controller('inputDateController',
		function (
			$scope,
			globalFactory,
			$timeout,
			appFirestoreHelper
		) {
			$scope.id = 'input-date-' + globalFactory.generateRandomId(7);
			$scope.value = null;
			$scope.diaSemana = null;

			const diasSemana = ['Dom', '2ª', '3ª', '4ª', '5ª', '6ª', 'Sab'];

			let disableWatchValue;

			const applyMask = _ => {
				VMasker(document.getElementById($scope.id)).maskPattern("99/99/9999");
			}

			const setData = v => {

				if (!v || v.length !== 10) {
					$('#' + $scope.id).removeClass('invalid').addClass('valid');
					$scope.diasSemana = null;

					return;
				}

				const d = moment(v, 'DD/MM/YYYY');

				if (d.isValid()) {
					$scope.model[$scope.fieldName] = d.format('DD/MM/YYYY');
					$scope.model[$scope.fieldName + '_yyyymmdd'] = d.format('YYYY-MM-DD');
					$scope.model[$scope.fieldName + '_timestamp'] = appFirestoreHelper.toTimestamp(d.toDate());
					$scope.model[$scope.fieldName + '_weak_day'] = d.day();

					$scope.diaSemana = diasSemana[d.day()];

					$('#' + $scope.id).removeClass('invalid').addClass('valid');
				} else {
					$scope.diasSemana = null;
					$('#' + $scope.id).removeClass('valie').addClass('invalid');
				}

			}

			const initWatchValue = _ => {
				stopWatchValue();

				disableWatchValue = $scope.$watch('value', (newValue) => {
					setData(newValue);
				})
			}

			const stopWatchValue = _ => {
				if (disableWatchValue) disableWatchValue();
				disableWatchValue = null;
			}

			$scope.$watch('model', newValue => {
				stopWatchValue();

				setData(newValue);

				initWatchValue();
			})

			$timeout(_ => {
				applyMask();
				initWatchValue();
			})

		})

	.directive('inputDate', function () {
		return {
			restrict: 'E',
			templateUrl: 'input-date/input-date.html',
			controller: 'inputDateController',
			replace: true,
			scope: {
				model: '=',
				fieldName: '@'
			}
		};
	});

export default ngModule;
