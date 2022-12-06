
const ngModule = angular.module('directives.loginBox', [])

	.controller('loginBoxController',
		function (
			$scope,
			appConfig,
			alertFactory,
			blockUiFactory,
			appAuthHelper,
			recoveryPasswordFactory,
			newPasswordFactory,
			globalFactory,
			newUserFactory,
			$window
		) {

			blockUiFactory.start();

			$scope.ready = false;
			$scope.appProfile = null;
			$scope.login = null;

			if (location.search.contains('clear')) {
				appAuthHelper.signOut();

				return;
			}

			$scope.loginModel = {};
			$scope.loginForm = null;

			$scope.loginFields = [
				{
					key: 'email',
					type: 'input',
					className: 'capitalize-email',
					templateOptions: {
						label: 'Email',
						type: 'text',
						maxlength: 128,
						minlength: 3,
						required: true,
						type: 'email',
						icon: 'fas fa-envelope'
					},
					ngModelElAttrs: {
						autocomplete: "current-email"
					}
				},
				{
					key: 'senha',
					type: 'input',
					templateOptions: {
						label: 'Senha',
						maxlength: 32,
						minlength: 3,
						required: true,
						type: 'password',
						icon: 'fas fa-lock'
					},
					ngModelElAttrs: {
						autocomplete: "current-password"
					}
				}
			];

			$scope.emailLogin = function () {
				if (!$scope.loginForm.$valid) {
					alertFactory.error('Existem campos obrigatórios não preenchidos. Verifique.');
					return;
				}
				appAuthHelper.signInWithEmail($scope.loginModel.email, $scope.loginModel.senha);
			}

			$scope.newUser = function () {
				newUserFactory.create();
			}

			$scope.googleLogin = function () {
				blockUiFactory.start();
				appAuthHelper.signInWithRedirect();
			}

			$scope.recoveryPassword = function () {
				recoveryPasswordFactory.show().then(function () { }).catch(function (e) { })
			}

			var checkMode = function () {

				var params = globalFactory.getSearchParams();

				if (!params.mode || !params.oobCode) { return; }

				if (params.mode == 'resetPassword') {
					blockUiFactory.start();

					firebaseProvider.auth.verifyPasswordResetCode(params.oobCode)

						.then(function () {
							blockUiFactory.stop();
							return newPasswordFactory.show(params);
						})

						.then(function () {
							$window.location.href = "/adm/login";
						})

						.catch(function (e) {
							blockUiFactory.stop();
							alertFactory.error('Oops... Não foi possível completar o processo. [' + firebaseAuthMessages[e.code] + ']').then(function () {
								$window.location.href = "/adm/login";
							})
						})
				}
			}

			appAuthHelper.ready()
				.then(_ => {
					$scope.appProfile = appConfig.appProfile();
					$scope.login = appConfig.get("/login");

					if (appAuthHelper.user) {
						$window.location.href = '/adm/home';
						return;
					}

					$scope.ready = true;
					blockUiFactory.stop();
				})

		}
	)

	.directive('loginBox', function () {
		return {
			restrict: 'E',
			templateUrl: 'login-box/login-box.html',
			controller: 'loginBoxController'
		};
	});

export default ngModule;
