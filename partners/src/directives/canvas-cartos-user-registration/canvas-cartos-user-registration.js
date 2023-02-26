'use strict';

const ngModule = angular.module('directives.canvas-cartos-user-registration', [])

	.factory('canvasCartosUserRegistrationFactory',
		function (
			$timeout
		) {

			let delegate = null;
			let successCallback = null;

			let Offcanvas = null;

			const modal = _ => {
				if (Offcanvas) { return Offcanvas; }

				var e = document.getElementById('canvas-cartos-user-registration');
				Offcanvas = new bootstrap.Offcanvas(e);

				return Offcanvas;
			}

			let open = callback => {
				successCallback = callback;
				if (delegate && typeof delegate.init === 'function') {
					delegate.init();
				}
				modal().show();
			};

			let close = _ => {
				modal().hide();
			}

			const callSuccessCallback = _ => {
				if (typeof successCallback === 'function') {
					successCallback();
				}
			}

			const initDelegate = obj => {
				delegate = obj;
			}

			return {
				open: open,
				close: close,
				initDelegate: initDelegate,
				callSuccessCallback: callSuccessCallback
			}

		}
	)


	.controller('canvasCartosUserRegistrationController',
		function (
			$scope,
			appAuthHelper,
			canvasCartosUserRegistrationFactory,
			userService,
			alertFactory,
			$timeout
		) {

			$scope._invalid = 0;
			$scope._usuarioNaoIniciado = 1;
			$scope._aguardandoCodigo = 2;

			$scope.status = $scope._usuarioNaoIniciado;

			$scope.profile = null;
			$scope.userStatus = null;

			$scope.form = { code: null };

			const applyMasks = _ => {
				$timeout(_ => {
					VMasker(document.getElementById('canvas-cartos-user-registration-codigo')).maskPattern('999999');
				})
			}

			const init = _ => {

				$scope.profile = appAuthHelper.profile;
				$scope.userStatus = appAuthHelper.status;

				if (!appAuthHelper.cartosUser) {
					$scope.status = $scope._usuarioNaoIniciado;
				}

				if (appAuthHelper.cartosUser && !$scope.userStatus.emailValidated) {
					$timeout(_ => {
						$scope.status = $scope._aguardandoCodigo;
						applyMasks();
					})
				}

			};

			canvasCartosUserRegistrationFactory.initDelegate({
				init: init
			});

			$scope.initAccount = _ => {

				userService.init({
					success: response => {
						canvasCartosUserRegistrationFactory.callSuccessCallback();
					}
				})

			}

			$scope.emailCode = _ => {
				if (!$scope.form.code || $scope.form.code.length !== 6) {
					alertFactory.info(`Informe o código que foi enviado para o email ${appAuthHelper.profile.email}.`);
					return;
				}
				userService.emailCode({
					code: $scope.form.code,
					success: response => {
						if (response.action === 'ready') {
							canvasCartosUserRegistrationFactory.callSuccessCallback();
							canvasCartosUserRegistrationFactory.close();
						}
						alertFactory.info(response.message);
					}
				})
			}


			$scope.emailResendCode = _ => {
				userService.emailResendCode({
					success: response => {
						$scope.userStatus.emailCanSendCode = false;
						alertFactory.info(response.message);
					}
				})
			}

		}
	)

	.directive('canvasCartosUserRegistration', function (
	) {
		return {
			restrict: 'E',
			templateUrl: 'canvas-cartos-user-registration/canvas-cartos-user-registration.html',
			controller: 'canvasCartosUserRegistrationController',
			scope: {}
		};
	});

export default ngModule;
