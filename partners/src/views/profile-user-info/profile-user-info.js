'use strict';

import config from './profile-user-info.config';

var ngModule = angular.module('views.profile-user-info', [
])

	.config(config)

	.controller('viewProfileUserInfoController', function (
		$scope,
		pageHeaderFactory,
		appAuthHelper,
		waitUiFactory,
		alertFactory,
		footerBarFactory,
		$location
	) {

		pageHeaderFactory.setModeLight('Seus dados');

		footerBarFactory.show();

		$scope.ready = false;
		$scope.newUser = false;

		const initForm = emailValidated => {
			$scope.formly = {
				model: null,
				form: null,
				fields: [
					{
						key: 'displayName',
						templateOptions: {
							label: 'Nome',
							required: true,
							placeholder: 'Nome completo',
							minlength: 3,
							maxlength: 60
						},
						type: 'input'
					},
					{
						key: 'cpf',
						templateOptions: {
							label: 'CPF',
							required: true
						},
						type: 'cpf',
						ngModelElAttrs: { disabled: 'true' }
					}, {
						key: 'phoneNumber',
						templateOptions: {
							label: 'Celular',
							required: true,
							international: false
						},
						type: 'celular',
						ngModelElAttrs: { disabled: 'true' }
					}, {
						key: 'email',
						templateOptions: {
							label: 'Email',
							required: true,
							placeholder: 'Seu melhor email',
							minlength: 6,
							maxlength: 180
						},
						type: 'email',
						ngModelElAttrs: emailValidated ? { disabled: 'true' } : {}
					},
					{
						key: 'dtNascimento',
						templateOptions: {
							label: 'Data de Nascimento',
							required: true
						},
						type: 'data'
					}
				]
			}
		}

		appAuthHelper.ready()
			.then(_ => {

				initForm(appAuthHelper.emailValidated);

				$scope.formly.model = appAuthHelper.profile;

				if (!$scope.formly.model) {
					appAuthHelper.signOut();
					return;
				}

				$scope.ready = true;
				waitUiFactory.hide();
			})

		$scope.onSubmit = _ => {

			if ($scope.formly.form.$valid) {

				waitUiFactory.start();

				appAuthHelper.updateUser({
					data: $scope.formly.model,
					success: _ => {
						waitUiFactory.stop();
						alertFactory.success('Dados atualizados com sucesso...');

						$location.path('/index');
						$location.replace();
					},
					error: e => {
						waitUiFactory.stop();
						alertFactory.error(e.message || e.data.error);
					}
				})

			}

		}

		/*
		$scope.$on('$destroy', function () {
		});
		*/

	});


export default ngModule;
