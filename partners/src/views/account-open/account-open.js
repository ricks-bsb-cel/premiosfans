'use strict';

import config from './account-open.config';

var ngModule = angular.module('views.profile-conta-empresa', [
])

	.config(config)

	.controller('viewAccountOpenController', function (
		$scope,
		pageHeaderFactory,
		appAuthHelper,
		profileService,
		waitUiFactory,
		$routeParams,
		$window,
		$location
	) {

		const _done = 'done';
		const _current = 'current';
		const _todo = 'todo';

		$scope.type = $routeParams.type;
		$scope.id = $routeParams.id;
		$scope.profile = null;

		$scope.ready = false;

		// Essa Zoeira toda é apenas para o back button funcionar corretamente
		// Quando o usuário inicia o cadastro de uma empresa que já havia começado antes...

		const redirectToId = $window.localStorage.getItem(`open-company-${$scope.id}`);

		if (redirectToId && redirectToId !== $scope.id) {
			$window.localStorage.removeItem(`open-company-${$scope.id}`);
			$window.localStorage.setItem(`back-to-account-choose-type-${redirectToId}`, 'back-to-account-choose-type');
			$location.path(`/account-open/${$scope.type}/${redirectToId}`).replace();
			return;
		} else {
			const backToId = $window.localStorage.getItem(`back-to-account-choose-type-${$scope.id}`);
			if (backToId && backToId !== 'back-to-account-choose-type') {
				$window.localStorage.removeItem(`back-to-account-choose-type-${$scope.id}`);
				$location.path(`/account-choose-type`).replace();
				return;
			}
		}

		// Fim da Zoeira

		if ($scope.type === 'pf') {
			pageHeaderFactory.setModeLight('Conta Pessoa Física');
		} else if ($scope.type === 'pj') {
			pageHeaderFactory.setModeLight('Conta Empresarial');
		} else {
			throw new Error('Invalid account type');
		}

		$scope.colors = {
			current: {
				background: 'gradient-blue',
				text: 'color-white',
				iconBackground: 'gradient-blue',
				icon: 'color-white'
			},
			done: {
				background: '',
				text: 'color-green-light',
				iconBackground: 'bg-green-light',
				icon: 'color-white'
			},
			todo: {
				background: '',
				text: 'color-gray-light',
				iconBackground: '',
				icon: 'color-gray-light'
			}
		};

		// $scope.colorClass = ['gradient-highlight', 'gradient-menu', 'gradient-green', 'gradient-red', 'gradient-orange', 'gradient-yellow', 'gradient-blue', 'gradient-teal', 'gradient-mint', 'gradient-pink', 'gradient-magenta', 'gradient-brown', 'gradient-gray', 'gradient-night', 'gradient-dark'];

		$scope.cards = [];

		let defaultOption = $scope.type === 'pj' ? 'empresa' : 'voce';

		const initCards = _ => {

			if ($scope.type === 'pj') {
				$scope.cards.push({
					id: 'empresa',	// profile-empresa
					label: 'Sua Empresa',
					info: 'Dados completos da sua empresa',
					infoDone: 'Informações já preenchidas!',
					icon: 'bi-building',
					status: _todo,
					href: `#!/account-open-company/${$scope.type}/${$scope.id}`
				});
				defaultOption = 'empresa';
			}

			$scope.cards.push({
				id: 'voce',	// profile-user
				label: 'Você',
				info: 'Seus dados pessoais',
				infoDone: 'Dados pessoais já preenchidos!',
				icon: 'bi-person-circle',
				status: _current,
				href: `#!/account-open-user/${$scope.type}/${$scope.id}`
			});

			$scope.cards.push({
				id: 'documentos', // profile-docs
				label: 'Documentos',
				info: 'Upload dos seus documentos',
				infoDone: 'Documentos enviados!',
				icon: 'bi-file-earmark-person',
				status: _todo,
				href: `#!/account-open-docs/${$scope.type}/${$scope.id}`
			});

			$scope.cards.push({
				id: 'aprovacao', // profile-aprovacao
				label: 'Enviar Pedido',
				info: 'Solicite a abertura da conta',
				icon: 'bi-cloud-check',
				status: _todo,
				href: `#!/account-open-send/${$scope.type}/${$scope.id}`
			});

		}

		$scope.href = c => {
			return c.status !== _todo ? c.href : null;
		}

		$scope.setCurrentCard = id => {
			let currentStatus = _done;

			$scope.cards.forEach(c => {
				if (c.id === id) {
					c.status = _current;
					currentStatus = _todo;
				} else {
					c.status = currentStatus;
				}
			})
		}

		appAuthHelper.ready()

			.then(_ => {
				$scope.profile = appAuthHelper.profile;

				return profileService.getNextOptionAbertura($scope.id);
			})

			.then(getNextOptionAberturaResult => {

				getNextOptionAberturaResult = getNextOptionAberturaResult || { option: defaultOption };

				initCards();

				// Se a posição não for encontrada, considera a primeira.
				if ($scope.cards.findIndex(f => { return f.id === getNextOptionAberturaResult.option; }) < 0) {
					getNextOptionAberturaResult.option = $scope.cards[0].id;
				}

				$scope.setCurrentCard(getNextOptionAberturaResult.option)

				$scope.ready = true;

				waitUiFactory.hide();
			})

			.catch(e => {
				console.info(e);
			})

	});


export default ngModule;
