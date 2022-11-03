'use strict';

import config from './campanhas-edit.config';

const ngModule = angular.module('views.contratos-edit', [
])

	.config(config)

	.controller('viewCampanhasEditController', function (
		$scope,
		$routeParams,
		navbarTopLeftFactory,
		collectionCampanhas,
		collectionEmpresas,
		appAuthHelper,
		toastrFactory,
		blockUiFactory,
		globalFactory,
		$timeout,
		$location
	) {

		$scope.collectionCampanhas = collectionCampanhas;
		$scope.idCampanha = $routeParams.id || null;
		$scope.ready = false;
		$scope.title = $scope.idCampanha ? "Edição de Campanha" : "Inclusão de Campanha";

		$scope.campanha = {
			id: $scope.idCampanha
		};

		$scope.forms = {
			main: null,
			faixa: null
		};

		const save = _ => {

			if (typeof $scope.campanha.ativo === 'undefined') $scope.campanha.ativo = false;

			console.info($scope.campanha);

			blockUiFactory.start();

			collectionCampanhas.save($scope.campanha)
				.then(_ => {
					$location.path('/campanhas');
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
				},
				{
					id: 'save',
					label: 'Salvar',
					onClick: save,
					icon: 'far fa-save'
				}
			];

			navbarTopLeftFactory.reset();
			navbarTopLeftFactory.extend(nav);
		}

		const initForms = _ => {
			$scope.forms = {
				main: {
					fields: [
						{
							key: 'titulo',
							templateOptions: {
								label: 'Título da Campanha',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
						},
						{
							key: 'dtSorteio',
							templateOptions: {
								label: 'Data do Sorteio',
								required: true
							},
							type: 'data',
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-8'
						},
						{
							key: 'url',
							templateOptions: {
								label: 'URL',
								required: true
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-8'
						},
						{
							key: 'template',
							templateOptions: {
								label: 'Template',
								required: true
							},
							type: 'ng-selector-front-template',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
						}
					],
					form: null
				},
				faixa: {
					fields: [
						{
							key: 'faixaInicio',
							defaultValue: 1,
							templateOptions: {
								label: 'Número Inicial',
								required: true
							},
							type: 'integer',
							className: 'col-12'
						},
						{
							key: 'faixaFinal',
							defaultValue: 999999,
							templateOptions: {
								label: 'Número Final',
								required: true
							},
							type: 'integer',
							className: 'col-12'
						}
					],
					form: null
				}
			};
		}

		const loadCampanha = idCampanha => {

			collectionCampanhas.getById(idCampanha)
				.then(result => {
					$scope.campanha = { ...result };

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

					if ($scope.idCampanha && $scope.idCampanha !== 'new') {
						initForms();

						loadCampanha($scope.idCampanha);
					} else {
						$scope.campanha.guidCampanha = globalFactory.guid();

						initForms();
						showNavbar();

						$scope.ready = true;
					}

				})

				.catch(e => {
					console.error(e);
				})
		}

		$timeout(_ => {
			init();
		})

		$scope.$on('$destroy', function () {
			$scope.collectionCampanhas.collection.destroySnapshot();
		});

	});


export default ngModule;
