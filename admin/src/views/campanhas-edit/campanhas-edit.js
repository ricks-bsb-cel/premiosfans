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
		alertFactory,
		blockUiFactory,
		globalFactory,
		$timeout,
		$location,
		premiosFansService
	) {

		/* não há nada mais apavorante do que alguem que acredita em sua própria luta, e é fanático por ela */

		const _qtdGrupos = 1000;
		const _qtdNumerosPorGrupo = 100;
		const _qtdNumerosDaSortePorTitulo = 2;
		const _vlTitulo = 10;
		const _sorteio = {
			ativo: false,
			dtSorteio: null,
			guidSorteio: globalFactory.guid(),
			deleted: false
		}

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

			if (!$scope.forms.main.form.$valid) {
				alertFactory.error('Existe um ou mais campos obrigatórios não preenchidos. Verifique.');
				return;
			}

			if (typeof $scope.campanha.ativo === 'undefined') $scope.campanha.ativo = false;

			if ($scope.campanha.influencers.filter(f => { return f.selected; }).length === 0) {
				alertFactory.error('Selecione um ou mais Influencers.');
				return;
			}

			blockUiFactory.start();

			collectionCampanhas.save($scope.campanha)
				.then(saveResult => {
					$location.path('/campanhas');
					blockUiFactory.stop();
				})
				.catch(e => {
					blockUiFactory.stop();
					toastrFactory.error(e.data.error);
				})

		}

		const generateTemplates = _ => {
			premiosFansService.generateTemplates({
				data: { idCampanha: $scope.campanha.id },
				blockUi: false
			});
		}

		$scope.ativar = _ => {
			alertFactory.yesno('Tem certeza que deseja ativar a Campanha?', _ => {
				premiosFansService.ativarCampanha({
					idCampanha: $scope.campanha.id
				});
			})
		}

		const showNavbar = _ => {

			let nav = [
				{
					id: 'back',
					route: '/campanhas/'
				},
				{
					id: 'generage',
					label: 'Gerar Templates',
					onClick: generateTemplates,
					icon: 'fas fa-refresh'
				}
			];

			if ($scope.campanha && !$scope.campanha.ativo) {
				nav.push(
					{
						id: 'save',
						label: 'Salvar',
						onClick: save,
						icon: 'far fa-save'
					}
				);

				if ($scope.campanha.id) {
					nav.push(
						{
							id: 'ativar',
							label: 'Ativar',
							onClick: _ => {
								$scope.ativar();
							},
							icon: 'fa fa-check'
						}
					);
				}
			}

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
							defaultValue: _vlTitulo,
							type: 'reais',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6'
						},
						{
							key: 'qtdNumerosDaSortePorTitulo',
							templateOptions: {
								label: 'Números por Título',
								required: true
							},
							defaultValue: _qtdNumerosDaSortePorTitulo,
							type: 'integer',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6'
						},
					],
					form: null
				},
				geracao: {
					fields: [
						{
							key: 'qtdGrupos',
							templateOptions: {
								label: 'Grupos',
								required: true
							},
							defaultValue: _qtdGrupos,
							type: 'integer',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-6'
						},
						{
							key: 'qtdNumerosPorGrupo',
							templateOptions: {
								label: 'Números por Grupo',
								required: true
							},
							defaultValue: _qtdNumerosPorGrupo,
							type: 'integer',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-6'
						},
					],
					form: null
				},
				detalhes: {
					fields: [
						{
							key: 'detalhes',
							templateOptions: {
								type: 'text',
								height: 240
							},
							type: 'html-editor'
						}
					],
					form: null
				},
				termos: {
					fields: [
						{
							key: 'termos',
							templateOptions: {
								type: 'text',
								height: 240
							},
							type: 'html-editor'
						}
					],
					form: null
				},
				politica: {
					fields: [
						{
							key: 'politica',
							templateOptions: {
								type: 'text',
								height: 240
							},
							type: 'html-editor'
						}
					],
					form: null
				},
				rodape: {
					fields: [
						{
							key: 'rodape',
							templateOptions: {
								type: 'text',
								height: 240
							},
							type: 'html-editor'
						}
					],
					form: null
				},
				regulamento: {
					fields: [
						{
							key: 'regulamento',
							templateOptions: {
								type: 'text',
								height: 240
							},
							type: 'html-editor'
						}
					],
					form: null
				}
			};
		}

		$scope.qtdNumeros = _ => {
			const qtdGrupos = $scope.campanha.qtdGrupos || 0;
			const qtdNumerosPorGrupo = $scope.campanha.qtdNumerosPorGrupo || 0;

			const total = (qtdGrupos * qtdNumerosPorGrupo) - 1;

			return total;
		}

		const loadCampanha = idCampanha => {
			collectionCampanhas.get(idCampanha)

				.then(result => {
					$scope.campanha = { ...result };

					$scope.campanha.vlTitulo = $scope.campanha.vlTitulo || _vlTitulo;
					$scope.campanha.qtdGrupos = $scope.campanha.qtdGrupos || _qtdGrupos;
					$scope.campanha.qtdNumerosPorGrupo = $scope.campanha.qtdNumerosPorGrupo || _qtdNumerosPorGrupo;
					$scope.campanha.qtdNumerosDaSortePorTitulo = $scope.campanha.qtdNumerosDaSortePorTitulo || _qtdNumerosDaSortePorTitulo;

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
						// New
						$scope.campanha = {
							guidCampanha: globalFactory.guid(),
							qtdGrupos: _qtdGrupos,
							qtdNumerosPorGrupo: _qtdNumerosPorGrupo,
							qtdNumerosDaSortePorTitulo: _qtdNumerosDaSortePorTitulo,
							vlTitulo: _vlTitulo,
							influencers: [],
							sorteios: [_sorteio]
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

		$timeout(_ => {
			init();
		})

		$scope.$on('$destroy', function () {
			$scope.collectionCampanhas.collection.destroySnapshot();
		});

	});


export default ngModule;
