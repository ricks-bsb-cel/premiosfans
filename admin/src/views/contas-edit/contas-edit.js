'use strict';

import config from './contas-edit.config';

const ngModule = angular.module('views.contas-edit', [
])

	.config(config)

	.controller('viewContasEditController', function (
		$scope,
		$routeParams,
		navbarTopLeftFactory,
		collectionContas,
		appAuthHelper,
		toastrFactory,
		blockUiFactory,
		globalFactory,
		$location
	) {

		// não há nada mais apavorante do que alguém que acredita em sua própria luta, e é fanático por ela

		$scope.collectionContas = collectionContas;
		$scope.idConta = $routeParams.id || null;
		$scope.ready = false;
		$scope.title = $scope.idCampanha ? "Edição de Conta" : "Inclusão de Conta";

		$scope.conta = {};

		$scope.forms = {
			conta: null
		};

		const save = _ => {

			blockUiFactory.start();

			collectionContas.save($scope.conta)
				.then(saveResult => {
					$location.path('/contas');
					blockUiFactory.stop();
				})
				.catch(e => {
					blockUiFactory.stop();
					toastrFactory.error(e.data.error);
				})

		}

		const showNavbar = _ => {

			let nav = [
				{
					id: 'back',
					route: '/campanhas/'
				}
			];

			nav.push(
				{
					id: 'save',
					label: 'Salvar',
					onClick: save,
					icon: 'far fa-save'
				}
			);

			navbarTopLeftFactory.reset();
			navbarTopLeftFactory.extend(nav);
		}

		const initForms = _ => {
			$scope.forms = {
				conta: {
					fields: [
						{
							key: 'titulo',
							templateOptions: {
								label: 'Título',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-9 col-xl-9'
						}
					],
					form: null
				}
			};
		}

		const loadConta = idConta => {
			collectionConta.get(idConta)

				.then(result => {
					$scope.conta = { ...result };

					showNavbar();

					$scope.ready = true;
				})

				.catch(e => {
					console.error(e);
				})
		}

		const init = _ => {
			appAuthHelper.ready()
				.then(_ => {

					if ($scope.idConta && $scope.idConta !== 'new') {
						initForms();

						loadConta($scope.idCampanha);
					} else {
						// New
						$scope.conta = {
							guidConta: globalFactory.guid()
						};

						initForms();
						showNavbar();

						$scope.ready = true;
					}

				})

				.catch(e => {
					console.error(e);
				})
		}

		init();

		$scope.$on('$destroy', function () {
			$scope.collectionContas.collection.destroySnapshot();
		});

	});


export default ngModule;
