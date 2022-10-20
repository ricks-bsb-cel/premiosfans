'use strict';

const ngModule = angular.module('services.contasService', [])

	.factory('contasService',
		function (
			appAuthHelper,
			$http,
			URLs,
			toastrFactory,
			blockUiFactory,
			alertFactory
		) {

			const updateBalance = function (attrs) {

				if (!attrs.idEmpresa || !attrs.idConta) {
					throw new Error('Informe idEmpresa e idConta');
				}

				toastrFactory.info('Solicitando atualização da conta...');

				$http({
					url: `${URLs.contas.balance}/${attrs.idEmpresa}/${attrs.idConta}?async=true&updateTransactions=true`,
					method: 'get',
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (response) {
						toastrFactory.success(`Atualização de saldo em andamento. ID: ${response.data.data.attributes.serviceId}. Por favor, aguarde alguns segundos até a conclusão da operação.`);
					},
					function (e) {
						console.error(e);
					}
				);

			};

			const updateTransactions = function (attrs) {

				if (!attrs.idEmpresa) {
					throw new Error('Informe idEmpresa');
				}

				toastrFactory.info('Solicitando atualização de transações...');

				$http({
					url: `${URLs.transaction.refresh}/${attrs.idEmpresa}`,
					method: 'get',
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (_) {
						toastrFactory.success(`Atualização de transações em andamento. Por favor, aguarde alguns segundos até a conclusão da operação.`);
					},
					function (e) {
						console.error(e);
					}
				);

			};

			const updatePixKeys = function (attrs) {

				if (!attrs.idEmpresa) {
					throw new Error('Informe idEmpresa');
				}

				toastrFactory.info('Solicitando atualização de Chaves Pix...');

				$http({
					url: `${URLs.pixKeys.refresh}/${attrs.idEmpresa}?async=true`,
					method: 'get',
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (_) {
						toastrFactory.success(`Atualização de Chaves Pix em andamento. Por favor, aguarde alguns segundos até a conclusão da operação.`);
					},
					function (e) {
						console.error(e);
					}
				);

			};

			const createPixKey = function (attrs) {

				if (
					!attrs.data ||
					!attrs.data.idEmpresa ||
					!attrs.data.idConta ||
					!attrs.data.tipo ||
					typeof attrs.success !== 'function' ||
					typeof attrs.error !== 'function'
				) {
					throw new Error('Informe idEmpresa, idConta e tipo');
				}

				debugger;

				blockUiFactory.start();

				$http({
					url: `${URLs.pixKeys.create}?async=true`,
					method: 'post',
					data: { data: attrs.data },
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (response) {
						blockUiFactory.stop();
						alertFactory.success(`O pedido da nova chave pix foi enviado. Por favor, aguarde alguns minutos até a conclusão da operação.`);
						attrs.success(response);
					},
					function (e) {
						blockUiFactory.stop();
						console.error(e);
						attrs.error(response);
					}
				);

			};


			const updateAccounts = function (attrs) {

				if (!attrs.idEmpresa) {
					throw new Error('Informe idEmpresa');
				}

				toastrFactory.info('Solicitando atualização de Contas...');

				$http({
					url: `${URLs.contas.account}/${attrs.idEmpresa}?async=true`,
					method: 'get',
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (_) {
						toastrFactory.success(`Atualização de Contas em andamento. Por favor, aguarde alguns segundos até a conclusão da operação.`);
					},
					function (e) {
						console.error(e);
					}
				);

			};

			return {
				updateBalance: updateBalance,
				updateTransactions: updateTransactions,
				updatePixKeys: updatePixKeys,
				createPixKey: createPixKey,
				updateAccounts: updateAccounts
			};
		}
	);

export default ngModule;
