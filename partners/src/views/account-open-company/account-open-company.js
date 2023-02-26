'use strict';

import config from './account-open-company.config';

var ngModule = angular.module('views.account-open-company', [
])

	.config(config)

	.controller('viewAccountOpenCompanyController', function (
		$scope,
		pageHeaderFactory,
		appAuthHelper,
		profileService,
		waitUiFactory,
		$window,
		$location,
		$routeParams,
		footerBarFactory,
		alertFactory
	) {

		pageHeaderFactory.setModeLight('Dados da sua Empresa');

		$scope.ready = false;

		$scope.type = $routeParams.type;
		$scope.id = $routeParams.id;

		footerBarFactory.hide();

		$scope.forms = [];

		const checkCnpj = cnpj => {
			profileService.getAccounts()
				.then(accounts => {
					if (accounts) {
						Object.keys(accounts).forEach(id => {
							let account = accounts[id];
							if (account.type === 'pj' && $scope.id !== id && account.cnpj === cnpj) {
								alertFactory.info('Você já está cadastrando esta empresa. Vamos te levar para o cadastro que está em andamento!', 'Oops!').then(_ => {
									$window.localStorage.setItem(`open-company-${$scope.id}`, id);
									$location.path(`/account-open-company/pj/${id}`);
									$location.replace();
								})
							}
						})
					}
				})
		}

		const initForms = empresa => {
			$scope.forms = {
				empresa: {
					model: empresa,
					form: null,
					fields: [
						{
							key: 'cnpj',
							templateOptions: {
								label: 'CNPJ',
								required: true,
							},
							type: 'cnpj',
							watcher: {
								listener: function (field, newValue) {
									checkCnpj(newValue);
								}
							},
						},
						{
							key: 'nome',
							templateOptions: {
								label: 'Nome Empresarial',
								required: true,
								minlength: 3,
								maxlength: 120
							},
							type: 'input'
						},
						{
							key: 'nomeFantasia',
							templateOptions: {
								label: 'Nome de Fantasia',
								required: true,
								minlength: 3,
								maxlength: 120
							},
							type: 'input'
						},
						{
							key: 'dtAbertura',
							templateOptions: {
								label: 'Data de Abertura',
								required: true
							},
							type: 'data'
						}
					]
				}
			}
		}

		appAuthHelper.ready()

			.then(_ => {
				return profileService.getAccount($routeParams.id);
			})

			.then(getEmpresaResult => {
				initForms(getEmpresaResult);
				$scope.ready = true;
				waitUiFactory.hide();
			})

			.catch(e => {
				console.error(e);
			});


		$scope.save = _ => {

			if ($scope.forms.empresa.form.$valid) {

				waitUiFactory.start();

				const accountPJ = angular.merge($scope.forms.empresa.model, {
					id: $scope.id,
					type: 'pj'
				});

				if (!accountPJ.cnpj) {
					throw new Error('Invalid cnpj value');
				}
				
				profileService.saveAccount(accountPJ, $scope.id)

					.then(_ => {
						return profileService.saveNextOptionAbertura($scope.id, 'voce');
					})

					.then(_ => {
						waitUiFactory.stop();
						$window.history.back();
					})

					.catch(e => {
						waitUiFactory.stop();
						console.info(e);
					})

			} else {
				alertFactory.error('Existem campos obrigatórios não preenchidos ou inválidos. Verifique.');
			}

		}

	});


export default ngModule;
