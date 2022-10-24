'use strict';

const ngModule = angular.module('directives.select.empresa', [])

	.controller('selectEmpresaModalController',
		function (
			$uibModalInstance,
			parm
		) {
			var $ctrl = this;

			$ctrl.empresas = parm.empresas;
			$ctrl.idEmpresaAtual = parm.idEmpresaAtual;

			$ctrl.selectEmpresa = id => {
				parm.changeEmpresaAtual(id);
			}

			$ctrl.cancel = function () {
				$uibModalInstance.dismiss();
			};
		})

	.factory('selectEmpresaFactory',
		function (
			$q,
			$uibModal
		) {

			const showModal = function (parm) {
				return $q(function (resolve, reject) {
					var modal = $uibModal.open({
						windowClass: 'select-empresa-modal',
						templateUrl: 'select-empresa/select-empresa-modal.html',
						controller: 'selectEmpresaModalController',
						controllerAs: '$ctrl',
						backdrop: false,
						size: 'lg',
						resolve: {
							parm: function () {
								return parm;
							}
						}
					});

					modal.result
						.then(function (data) {
							resolve(data);
						}, function () {
							reject();
						});

				})
			}

			const show = function (parm) {

				return $q(function (resolve, reject) {
					showModal(parm)
						.then(function () {
							resolve();
						})
						.catch(function () {
							reject();
						})
				})
			}

			return {
				show: show
			};
		}
	)

	.controller('selectEmpresaController',
		function (
			$scope,
			appAuthHelper,
			selectEmpresaFactory
		) {

			$scope.ready = false;
			$scope.idEmpresaAtual = null;
			$scope.empresaAtual = null;
			$scope.empresas = [];

			const changeEmpresaAtual = id => {
				appAuthHelper.setEmpresaUser(id);
			}

			$scope.selectEmpresa = _ => {
				if ($scope.empresas.length <= 1) { return; }

				selectEmpresaFactory.show({
					empresas: $scope.empresas,
					changeEmpresaAtual: changeEmpresaAtual,
					idEmpresaAtual: $scope.idEmpresaAtual
				});
			}

			appAuthHelper.ready()
				.then(_ => {
					$scope.empresas = appAuthHelper.profile.user.empresas || [];
					$scope.idEmpresaAtual = appAuthHelper.profile.user.empresaAtual ? appAuthHelper.profile.user.empresaAtual.id : null;

					$scope.empresaAtual = $scope.empresas.filter(f => {
						return f.id === $scope.idEmpresaAtual
					});

					if ($scope.empresaAtual.length) $scope.empresaAtual = $scope.empresaAtual[0];

					angular.element(document.querySelector('#sidebar-content-wait')).hide();
					angular.element(document.querySelector('#sidebar-content')).show();

					$scope.ready = true;
				})

		})

	.directive('selectEmpresa', function () {
		return {
			restrict: 'E',
			replace: true,
			controller: 'selectEmpresaController',
			templateUrl: 'select-empresa/select-empresa.html'
		};
	});

export default ngModule;
