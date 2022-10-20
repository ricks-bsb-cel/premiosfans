'use strict';

import { getMultiFactorResolver } from "firebase/auth";

const ngModule = angular.module('services.folhaService', [])

	.factory('folhaService',
		function (
			appAuthHelper,
			$http,
			URLs,
			blockUiFactory,
			globalFactory
		) {

			const setFuncionario = function (attrs) {

				if (
					!attrs.data ||
					typeof attrs.success !== 'function' ||
					typeof attrs.error !== 'function'
				) {
					throw new Error('Informe dados, success e erro functions');
				}

				blockUiFactory.start();

				attrs.data = {
					"nome": attrs.data.nome,
					"cpf": attrs.data.cpf,
					"celular": attrs.data.celular,
					"dtNascimento": attrs.data.dtNascimento,
					"email": attrs.data.email,
					"ativo": attrs.data.ativo,
					"endereco_rua": attrs.data.endereco_rua,
					"endereco_bairro": attrs.data.endereco_bairro,
					"endereco_cidade": attrs.data.endereco_cidade,
					"endereco_estado": attrs.data.endereco_estado,
					"endereco_numero": attrs.data.endereco_numero,
					"endereco_complemento": attrs.data.endereco_complemento,
					"endereco_cep": globalFactory.onlyNumbers(attrs.data.endereco_cep)
				};

				$http({
					url: URLs.folha.funcionario.set,
					method: 'post',
					data: attrs.data,
					headers: {
						'Authorization': 'Bearer ' + appAuthHelper.token
					}
				}).then(
					function (response) {
						blockUiFactory.stop();
						attrs.success(response.data);
					},
					function (e) {
						blockUiFactory.stop();
						console.error(e);
						attrs.error(response);
					}
				);

			};

			const sendAsyncFuncionario = function (data) {

				return new Promise((resolve, reject) => {

					if (!data || !data.cpf) {
						throw new Error('Informe dados, success e erro functions');
					}

					const payload = {
						data: {
							idEmpresa: appAuthHelper.profile.user.idEmpresa,
							cpf: globalFactory.onlyNumbers(data.cpf),
							nome: data.nome || null,
							celular: data.celular ? globalFactory.onlyNumbers(data.celular) : null,
							email: data.email || null
						}
					};

					$http({
						url: URLs.folha.funcionario.sendAsync,
						method: 'post',
						data: payload,
						headers: {
							'Authorization': 'Bearer ' + appAuthHelper.token
						}
					}).then(
						function (response) {
							return resolve(response);
						},
						function (e) {
							return reject(e);
						}
					);

				})

			};

			return {
				setFuncionario: setFuncionario,
				sendAsyncFuncionario: sendAsyncFuncionario
			};
		}
	);

export default ngModule;
