'use strict';

import config from './contratos-edit.config';

const ngModule = angular.module('views.contratos-edit', [
])

	.config(config)

	.controller('viewContratosEditController', function (
		$scope,
		$routeParams,
		navbarTopLeftFactory,
		collectionContratos,
		collectionContratosProdutos,
		appAuthHelper,
		toastrFactory,
		blockUiFactory,
		globalFactory,
		collectionAdmConfigPath,
		$timeout,
		$location
	) {

		$scope.collectionContratos = collectionContratos;
		$scope.idContrato = $routeParams.id || null;
		$scope.edit = $routeParams.edit === '1';
		$scope.ready = false;

		$scope.title = "Contrato";

		$scope.titles = {};
		$scope.contrato = {};
		$scope.forms = {
			main: null,
			cobranca: null
		};

		const showTitles = _ => {
			let promisses = [];

			const ids = [
				'SJitMMc2NvLkIdnCbSOF',
				'H0QBd7rgbsaApsazEQbS',
				'rlbUboVFont6Y6Z62UMU'
			];

			ids.forEach(id => { promisses.push(collectionAdmConfigPath.getById(id)); });

			Promise.all(promisses)
				.then(result => {
					$timeout(_ => {
						$scope.titles.clientes = result[0];
						$scope.titles.produtos = result[1];
						$scope.titles.cobrancas = result[2];
					})
				})

		}

		$scope.produtosCobranca = [];

		const save = _ => {

			blockUiFactory.start();

			collectionContratos.save($scope.contrato)
				.then(_ => {
					$location.path('/contratos');
					blockUiFactory.stop();
				})
				.catch(e => {
					blockUiFactory.stop();
					toastrFactory.error(e.data.error);
				})
		}

		const showNavbar = _ => {

			let nav = [{
				id: 'back',
				route: '/contratos/'
			}];

			const addSave = _ => {
				const l = $scope.contrato.id ? 'Revisar Contrato' : 'Salvar';
				const c = `btn btn-block ${$scope.contrato.id ? 'btn-danger' : 'btn-primary'}`
				nav.push({ id: 'save', label: l, onClick: save, class: c, icon: 'far fa-save' });
			}

			const addEdit = _ => {
				nav.push({ id: 'edit', label: 'Revisar Contrato', route: `/contratos-edit/${$scope.idContrato}/1`, class: 'btn btn-block btn-primary', icon: 'fas fa-edit mr-2' });
			}

			if ($scope.contrato && $scope.contrato.situacao === 'ativo') {
				if ($scope.edit) {
					addSave();
				} else {
					addEdit();
				}
			}

			if (
				$scope.contrato &&
				(
					$scope.contrato.situacao === 'em-revisao' ||
					$scope.contrato.situacao === 'preparacao'
				)
			) {
				addSave();
			}

			navbarTopLeftFactory.reset();
			navbarTopLeftFactory.extend(nav);
		}

		const initForms = _ => {
			$scope.forms = {
				main: {
					fields: [
						{
							key: 'idCliente',
							templateOptions: {
								label: 'Nome',
								required: true,
								data: {
									prefixo: 'cliente_'
								}
							},
							type: 'ng-selector-cliente',
							className: 'col-12',
							ngModelElAttrs: !$scope.idContrato || $scope.idContrato === 'new' ? {} : { disabled: 'true' }
						},
						{
							key: 'cliente_cpfcnpj_formatted',
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'CPF/CNPJ'
							},
							ngModelElAttrs: { disabled: 'true' }
						},
						{
							key: 'cliente_celular_formatted',
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'Celular/Whatsapp'
							},
							ngModelElAttrs: { disabled: 'true' }
						},
						{
							key: 'cliente_email',
							className: 'col-12',
							templateOptions: {
								label: 'Email',
								type: 'text',
								type: 'email'
							},
							type: 'input',
							ngModelElAttrs: { disabled: 'true' }
						}
					],
					form: null
				},
				cobranca: {
					fields: [
						{
							key: 'inicioContrato',
							type: 'data-mmyyyy',
							className: 'col-4',
							templateOptions: {
								label: 'Início (mês/ano)',
								required: true
							},
							ngModelElAttrs: $scope.edit ? {} : { disabled: 'true' }
						},
						{
							key: 'diaMesCobranca',
							templateOptions: {
								label: 'Dia',
								required: true,
							},
							className: 'col-3',
							type: 'data-dd',
							ngModelElAttrs: $scope.edit ? {} : { disabled: 'true' }
						},
						{
							key: 'situacao',
							templateOptions: {
								label: 'Situação',
								required: true
							},
							type: 'ng-selector-situacao-contrato',
							className: 'col-5',
							ngModelElAttrs: { disabled: 'true' }
						},
						{
							key: 'obs',
							type: 'textarea',
							templateOptions: {
								label: 'Observações'
							},
							className: 'col-12 obs',
							ngModelElAttrs: $scope.edit ? {} : { disabled: 'true' }
						}
					],
					form: null
				}
			};
		}

		const loadContrato = idContrato => {
			collectionContratos.getById(idContrato)
				.then(result => {
					$scope.contrato = angular.copy(result);
					$scope.contrato.produtos = $scope.contrato.produtos || [];

					$scope.contrato.inicioContrato = result.inicioContrato_mmyyyy;

					$scope.title = `${$scope.edit ? 'Revisão de ' : ''}Contrato ${$scope.contrato.codigoContrato}-${$scope.contrato.codigoContratoVersao}`;

					if ($scope.edit && $scope.contrato.situacao !== 'ativo') {
						$scope.edit = false;
					}

					if ($scope.edit && $scope.contrato.situacao === 'ativo') {
						$scope.contrato.situacao = 'em-revisao';
					}

					return collectionContratosProdutos.getProdutosContrato(idContrato, $scope.contrato.idCliente);
				})

				.then(resultCollectionProdutos => {
					$scope.contrato.produtos = resultCollectionProdutos;
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
					showTitles();

					if ($scope.idContrato && $scope.idContrato !== 'new') {
						initForms();

						loadContrato($scope.idContrato);
					} else {
						$scope.contrato = {
							situacao: 'preparacao',
							produtos: [],
							guidContrato: globalFactory.guid()
						};
						$scope.edit = true;
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
			$scope.collectionContratos.collection.destroySnapshot();
		});

	});


export default ngModule;
