
const ngModule = angular.module('directives.login-block', [])

	.controller('loginBlockController',
		function (
			$scope,
			appAuthHelper,
			globalFactory,
			userService,
			waitUiFactory,
			alertFactory,
			$timeout,
			$location,
			$window
		) {

			const _start = 'start';
			const _infoSendCode = 'info-send-code';
			const _askCode = 'ask-code';

			let divHeight = {};
			let divTitle = {};

			divHeight[_start] = '432px';
			divHeight[_infoSendCode] = '337px';
			divHeight[_askCode] = '386px';

			divTitle[_start] = 'Acesse sua Conta';
			divTitle[_infoSendCode] = 'Código de Acesso';
			divTitle[_askCode] = 'Informe o Código';

			waitUiFactory.start();

			$scope.currentDiv = _start;

			$scope.data = {
				cpf: null,
				celular: null,
				codigo: null,
				agree: false
			}

			const applyMasks = _ => {
				$timeout(_ => {
					VMasker(document.getElementById('login-block-cpf')).maskPattern('999.999.999-99');
					VMasker(document.getElementById('login-block-celular')).maskPattern('(99) 9 9999-9999');
					VMasker(document.getElementById('login-block-codigo')).maskPattern('999999');
				})
			}

			$scope.setCurrentDiv = value => {
				$timeout(_ => {
					angular.element(document.getElementById("menu-login")).css('height', divHeight[value]);
					angular.element(document.querySelectorAll("#menu-login h2.title")).html(divTitle[value]);
					$scope.currentDiv = value;
				})
			}

			const isReady = _ => {
				$timeout(_ => {
					waitUiFactory.stop();
				})
			}

			$scope.checkData = _ => {

				const cpf = globalFactory.onlyNumbers($scope.data.cpf);
				const celular = globalFactory.onlyNumbers($scope.data.celular);

				if (!cpf || cpf.length !== 11 || celular.length !== 11) {
					alertFactory.error('Informe corretamente seu CPF e Celular...');
					return;
				}

				if (cpf.length === 11 && !globalFactory.isCPFValido(cpf)) {
					alertFactory.error('O CPF informado é inválido...');
					return;
				}

				const checkCpfCelular = _ => {

					waitUiFactory.start();

					userService.checkCpfCelular(cpf, celular,
						result => {
							waitUiFactory.stop();

							if (result.error) {
								alertFactory.error(result.msg);
							} else {
								$scope.setCurrentDiv(_infoSendCode);
							}
						}
					)
				}
				
				appAuthHelper.ready()
					.then(currentUser => {
						if (!currentUser) {
							checkCpfCelular();
						} else {
							waitUiFactory.start();
							appAuthHelper.signOut(false, _ => {
								checkCpfCelular();
							});
						}
					})

			}

			$scope.sendCode = _ => {

				waitUiFactory.start();

				const celular = globalFactory.onlyNumbers($scope.data.celular);

				return appAuthHelper.sendCodeToNumber({
					celular: celular,
					success: _ => {
						waitUiFactory.stop();
						$scope.setCurrentDiv(_askCode);
					},
					error: e => {
						waitUiFactory.stop();
						console.error(e);
					}
				})

			}

			$scope.checkCode = _ => {

				const codigo = globalFactory.onlyNumbers($scope.data.codigo);
				const cpf = globalFactory.onlyNumbers($scope.data.cpf);
				const celular = globalFactory.onlyNumbers($scope.data.celular);

				if (!codigo || codigo.length !== 6) {
					alertFactory.info('Informe o código com 6 dígitos');
					return;
				}

				waitUiFactory.start();

				// Se código correto vai dar reload...
				appAuthHelper.checkCode({
					codigo: codigo,
					celular: celular,
					cpf: cpf,
					error: _ => {
						waitUiFactory.stop();
					},
					success: _ => {
						$location.path('/splash');
						$location.replace();
						$window.location.reload();
						return;
					}
				})
			}

			$timeout(_ => {
				appAuthHelper.initRecaptchaVerifier(
					{
						container: 'submit-code',
						ready: _ => {
							isReady();
						}
					}
				);
				applyMasks();
			})

		}
	)

	.directive('loginBlock', function () {
		return {
			restrict: 'E',
			templateUrl: 'login-block/login-block.html',
			controller: 'loginBlockController'
		};
	});

export default ngModule;
