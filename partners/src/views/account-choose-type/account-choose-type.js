'use strict';

import config from './account-choose-type.config';

var ngModule = angular.module('views.account-choose-type', [
])

	.config(config)

	.controller('viewAccountChooseTypeController', function (
		$scope,
		pageHeaderFactory,
		appAuthHelper,
		globalFactory,
		waitUiFactory,
		profileService,
		footerBarFactory,
		$window
	) {

		$scope.ready = false;
		$scope.profile = null;
		$scope.isLocalHost = $window.location.hostname === 'localhost';

		$scope._contaNaoSolicitada = 0;
		$scope._contaSolicitada = 1;
		$scope._contaAberta = 2;

		$scope.cartos = {
			status: {
				approved: 'APPROVED'
			}
		}

		$scope.newPJ = globalFactory.guid();

		// Contas do cliente (estão no Realtime!)
		let accounts = [];

		pageHeaderFactory.setModeLight('Abertura de Contas');

		footerBarFactory.show();
		waitUiFactory.show();

		$scope.accounts = _ => {
			let result = [];

			if (!$scope.ready || !accounts || Object.keys(accounts).length === 0) { result; }

			Object.keys(accounts).forEach(k => {
				let account = angular.merge(accounts[k], { status: $scope._contaNaoSolicitada });
				let i = appAuthHelper.getCartosAccounts()
					.findIndex(f => {
						return account.cpf === f.documentNumber ||
							account.cnpj === f.documentNumber;
					});

				if (i >= 0) { account.status = $scope._contaAberta; }

				result.push(account);
			})

			return result;
		}

		appAuthHelper.ready()

			.then(_ => {
				waitUiFactory.show();

				$scope.profile = appAuthHelper.profile;

				return profileService.getAccounts();
			})

			.then(promiseResult => {
				accounts = promiseResult;

				$scope.ready = true;

				waitUiFactory.hide();
			})

			.catch(e => {
				if (e.status === 420) {
					$scope.ready = true;
					waitUiFactory.hide();
				} else {
					console.info(e);
				}
			})

	});

export default ngModule;
