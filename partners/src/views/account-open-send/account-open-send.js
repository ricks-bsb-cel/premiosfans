'use strict';

import config from './account-open-send.config';

var ngModule = angular.module('views.account-open-send', [
])

	.config(config)

	.controller('viewAccountOpenSendController', function (
		$scope,
		profileService,
		pageHeaderFactory,
		appAuthHelper,
		waitUiFactory,
		alertFactory,
		$routeParams,
		userService,
		$location,

		canvasCartosUserRegistrationFactory
	) {

		pageHeaderFactory.setModeLight('Solicitação de Abertura');

		$scope.ready = false;
		$scope.type = $routeParams.type;
		$scope.id = $routeParams.id;

		$scope.userData = null;
		$scope.accountData = null;

		appAuthHelper.ready()

			.then(_ => {

				return Promise.all([
					profileService.getUser(),
					profileService.getAccount($scope.id)
				]);

			})

			.then(data => {

				$scope.userData = data[0];
				$scope.accountData = data[1];

				$scope.ready = true;
				waitUiFactory.hide();

			})

			.catch(e => {

				if (e.data?.error) {
					alertFactory.error(e.data?.error);
				} else {
					alertFactory.error(e);
				}

			});

		const callAccountOpen = _ => {
			alertFactory.yesno('Tem certeza que deseja solicitar a abertura de uma conta com os dados informados?', 'Abertura de Conta').then(_ => {
				userService.accountOpen({
					type: $scope.type,
					CpfCnpj: $scope.accountData.type === 'pf' ? $scope.accountData.cpf : $scope.accountData.cnpj,
					success: result => {

						if (result.error?.message) {
							alertFactory.error(result.error.message);
						} else {
							alertFactory.info('Solicitação de abertura de conta enviada com sucesso.');
						}

						$location.path('/account-choose-type');
						$location.replace();
					}
				})
			})
		}

		$scope.submitAccountOpen = _ => {

			$scope.showUserData = false;
			$scope.showOperations = true;

			// Se não existir usuário na Cartos ou usuário ainda não confirmou o email.
			if (!appAuthHelper.cartosUser || !appAuthHelper.emailValidated) {
				canvasCartosUserRegistrationFactory.open(callAccountOpen);
				return;
			}

			callAccountOpen();

		}

	});

export default ngModule;
