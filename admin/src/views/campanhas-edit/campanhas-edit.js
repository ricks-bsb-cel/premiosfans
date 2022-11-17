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

		$scope.campanha = {};

		$scope.forms = {
			main: null,
			faixa: null
		};

		const save = _ => {

			if (typeof $scope.campanha.ativo === 'undefined') $scope.campanha.ativo = false;

			blockUiFactory.start();

			collectionCampanhas.save($scope.campanha)
				.then(saveResult => {

					premiosFansService.generateTemplates({
						data: { idCampanha: saveResult.id },
						blockUi: false
					});

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
								label: 'Título',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-9 col-xl-9'
						},
						{
							key: 'url',
							templateOptions: {
								label: 'URL',
								required: true
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-3 col-xl-3'
						},
						{
							key: 'subTitulo',
							templateOptions: {
								label: 'SubTítulo',
								type: 'text',
								required: false,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
						},
						{
							key: 'detalhes',
							templateOptions: {
								label: 'Detalhes',
								type: 'text',
								required: false,
								minlength: 3,
								maxlength: 64
							},
							type: 'textarea',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
						},
						{
							key: 'template',
							templateOptions: {
								label: 'Template',
								required: true
							},
							type: 'ng-selector-front-template',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12'
						},
						{
							key: 'vlTitulo',
							templateOptions: {
								label: 'Valor',
								required: true
							},
							type: 'reais',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6'
						},
						{
							key: 'qtdNumerosDaSortePorTitulo',
							templateOptions: {
								label: 'Números por Título',
								required: true
							},
							defaultValue: 2,
							type: 'integer',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6'
						},
					],
					form: null
				}
			};
		}

		const loadCampanha = idCampanha => {
			collectionCampanhas.get(idCampanha)

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
