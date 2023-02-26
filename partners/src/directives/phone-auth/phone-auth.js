
const ngModule = angular.module('directives.phone-auth', [])

	.controller('phoneAuthController',
		function (
			$scope,
			appAuthHelper,
			waitUiFactory,
			alertFactory,
			globalFactory,
			$timeout
		) {

			$scope.contentEnviarCodigo = 0;
			$scope.contentReceberCodigo = 1;
			$scope.codigo = null;

			$scope.currentContent = $scope.contentEnviarCodigo;

			const canvasElement = document.querySelectorAll('#phone-auth')[0];
			const offCanvas = new bootstrap.Offcanvas(canvasElement);

			$scope.delegate = $scope.delegate || {};
			$scope.phoneData = null;

			$scope.delegate.startValidation = phoneData => {
				$scope.phoneData = phoneData;
				offCanvas.show();
			}

			$scope.voltar = _ => {
				$scope.currentContent = $scope.contentEnviarCodigo;
				$scope.codigo = null;
			}

			$scope.checkCode = _ => {

				waitUiFactory.start();

				const codigo = globalFactory.onlyNumbers($scope.codigo);

				if (!codigo || codigo.length !== 6) {
					alertFactory.error('Informe o código de 6 dígitos que foi enviado para o celular.');
					return;
				}

				appAuthHelper.checkCode({
					codigo: codigo,
					celular: $scope.phoneData.celular,
					cpf: $scope.phoneData.cpf,
					error: _ => {
						waitUiFactory.stop();
					},
					success: user => {
						offCanvas.hide();
						$scope.delegate.continue(user);
					}
				})
			}

			$scope.sendCode = _ => {

				waitUiFactory.start();

				appAuthHelper.sendCodeToNumber({
					celular: $scope.phoneData.celular,
					success: _ => {
						$timeout(_ => {
							$scope.currentContent = $scope.contentReceberCodigo;
							waitUiFactory.stop();
						})
					},
					error: e => {
						waitUiFactory.stop();
						console.error(e);
					}
				})

			}

			$scope.close = _ => {
				offCanvas.hide();
			}

		}
	)

	.directive('phoneAuth', function (
	) {
		return {
			restrict: 'E',
			templateUrl: 'phone-auth/phone-auth.html',
			controller: 'phoneAuthController',
			scope: {
				delegate: '='
			}
		};
	});

export default ngModule;
