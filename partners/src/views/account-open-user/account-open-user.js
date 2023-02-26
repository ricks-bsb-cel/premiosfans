'use strict';

import config from './account-open-user.config';

var ngModule = angular.module('views.account-open-user', [
])

	.config(config)

	.controller('viewAccountOpenUserController', function (
		$scope,
		pageHeaderFactory,
		appAuthHelper,
		profileService,
		waitUiFactory,
		alertFactory,
		formlyFactory,
		$window,
		$routeParams,
		footerBarFactory
	) {

		pageHeaderFactory.setModeLight('Seus dados pessoais');

		$scope.ready = false;
		$scope.forms = null;

		$scope.type = $routeParams.type;
		$scope.id = $routeParams.id;

		$scope.cartosUser = null;

		footerBarFactory.hide();

		const initForms = modelUser => {
			$scope.forms = {
				user: {
					model: modelUser,
					form: null,
					fields: [
						{
							key: 'displayName',
							type: 'input',
							templateOptions: {
								label: 'Nome',
								required: true,
								placeholder: 'Nome completo',
								minlength: 3,
								maxlength: 60
							},
							parsers: [formlyFactory.toUpperCase],
							formatters: [formlyFactory.toUpperCase],
							ngModelElAttrs: Boolean($scope.cartosUser) ? { disabled: 'true' } : {}
						},
						{
							key: 'cpf',
							templateOptions: {
								label: 'CPF',
								required: true
							},
							type: 'cpf',
							ngModelElAttrs: { disabled: 'true' }
						},
						{
							key: 'phoneNumber',
							templateOptions: {
								label: 'Celular',
								required: true,
								international: false
							},
							type: 'celular',
							ngModelElAttrs: { disabled: 'true' }
						},
						{
							key: 'email',
							type: 'email',
							templateOptions: {
								label: 'Email',
								required: true,
								placeholder: 'Seu melhor email',
								minlength: 6,
								maxlength: 180
							},
							parsers: [formlyFactory.toLowerCase],
							formatters: [formlyFactory.toLowerCase],
							ngModelElAttrs: Boolean($scope.cartosUser) ? { disabled: 'true' } : {}
						},
						{
							key: 'dtNascimento',
							type: 'data',
							templateOptions: {
								label: 'Data de Nascimento',
								required: true
							},
							ngModelElAttrs: Boolean($scope.cartosUser) ? { disabled: 'true' } : {}
						}
					]
				}
			};
		}

		appAuthHelper.ready()

			.then(_ => {

				$scope.cartosUser = appAuthHelper.cartosUser;
				const modelUser = appAuthHelper.appUserData.user || appAuthHelper.profile;

				initForms(modelUser);

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


		$scope.save = _ => {

			if (!$scope.forms.user.form.$valid) {
				alertFactory.error('Existem dados inválidos.');
				return;
			}

			waitUiFactory.start();

			let promises = [
				profileService.saveUser($scope.forms.user.model),
				profileService.saveNextOptionAbertura($scope.id, 'documentos')
			];

			if ($scope.type === 'pf') {
				// Pedido de abertura de conta PF
				const accountPF = angular.merge($scope.forms.user.model, {
					id: $scope.id,
					type: 'pf'
				});
				promises.push(profileService.saveAccount(accountPF, accountPF.cpf));
			}

			Promise.all(promises)

				.then(_ => {
					waitUiFactory.stop();
					$window.history.back();
				})

				.catch(e => {
					waitUiFactory.stop();
					console.info(e);
				})


		}

	});


export default ngModule;
