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
		$location,
		premiosFansService
	) {

		// não há nada mais apavorante do que alguém que acredita em sua própria luta, e é fanático por ela

		$scope.collectionContas = collectionContas;
		$scope.idConta = $routeParams.id || null;
		$scope.ready = false;
		$scope.title = $scope.idCampanha ? "Edição de Conta" : "Inclusão de Conta";

		$scope.conta = {};
		$scope.forms = {};

		const save = _ => {

			console.info($scope.conta);

			blockUiFactory.start();

			collectionContas.save($scope.conta)
				.then(_ => {
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
							key: 'documentNumber',
							type: 'cnpj',
							className: 'col-12 document-number',
							templateOptions: {
								label: 'CNPJ',
								type: 'text',
								required: true
							}
						},
						{
							key: 'companyName',
							type: 'input',
							className: 'col-12',
							templateOptions: {
								label: 'Nome da Empresa',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							}
						},
						{
							key: 'tradingName',
							type: 'input',
							className: 'col-12',
							templateOptions: {
								label: 'Nome de Fantasia',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							}
						},
						{
							key: 'legalModality',
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
							defaultValue: 'LTDA',
							templateOptions: {
								label: 'Modalidade Legal',
								type: 'text',
								required: true,
							}
						},
						{
							key: 'stateRegistration',
							type: 'ng-selector-estado',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xl-8',
							templateOptions: {
								label: 'Estado de Registro',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							}
						},
						{
							key: 'openCompanyDate',
							type: 'data',
							className: 'col-12',
							templateOptions: {
								label: 'Data de Abertura',
								type: 'text',
								required: true,
							}
						},
						{
							key: 'contact.mobilePhone',
							type: 'telefone',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'Telefone de Contato',
								type: 'text',
								required: true,
							}
						},
						{
							key: 'contact.email',
							type: 'email',
							className: 'col-xs-12 col-sm-12 col-md-12 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'eMail de Contato',
								type: 'text',
								required: true,
							}
						}
					],
					form: null
				},
				enderecoEmpresa: {
					fields: [
						{
							key: 'address.postalCode',
							type: 'mask-pattern',
							className: 'col-12 postal-code',
							templateOptions: {
								label: 'CEP',
								type: 'text',
								mask: '99 999 999',
								required: true
							},
							watcher: {
								listener: function (field, newValue, oldValue, scope) {
									if (!newValue || newValue === oldValue || newValue.length !== 10) return;
									premiosFansService.cep({
										data: { cep: newValue },
										success: response => {
											if (response.errors) return;
											scope.model.address.publicNameStreet = response.street || null;
											scope.model.address.district = response.neighborhood || null;
											scope.model.address.city = response.city || null;
											scope.model.address.state = response.state || null;
										}
									})
								}
							}
						},
						{
							key: 'address.publicNameStreet',
							templateOptions: {
								label: 'Rua, Avenida, Quadra, etc',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-8'
						},
						{
							key: 'address.numberHome',
							templateOptions: {
								label: 'Número',
								type: 'text',
								required: true,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-4'
						},
						{
							key: 'address.district',
							templateOptions: {
								label: 'Bairro',
								type: 'text',
								required: true,
								maxlength: 64
							},
							type: 'input',
							className: 'col-12'
						},
						{
							key: 'address.city',
							templateOptions: {
								label: 'Cidade',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-8'
						},
						{
							key: 'address.state',
							type: 'ng-selector-estado',
							templateOptions: {
								label: 'Estado',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-4'
						},
						{
							key: 'address.complement',
							templateOptions: {
								label: 'Complemento',
								type: 'text',
								maxlength: 64
							},
							type: 'input',
							className: 'col-12'
						}
					],
					form: null
				},
				representante: {
					fields: [
						{
							key: 'companyRepresentative.cpf',
							type: 'cpf',
							className: 'col-12 document-number',
							templateOptions: {
								label: 'CPF',
								type: 'text',
								required: true
							}
						},
						{
							key: 'companyRepresentative.name',
							type: 'input',
							className: 'col-12',
							templateOptions: {
								label: 'Nome',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							}
						},
						{
							key: 'companyRepresentative.politicallyExposed',
							className: 'col-12',
							defaultValue: false,
							templateOptions: {
								title: 'Politicamente Exposto',
							},
							type: 'custom-checkbox'
						},
						{
							key: 'companyRepresentative.contact.mobilePhone',
							type: 'telefone',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'Telefone de Contato',
								type: 'text',
								required: true,
							}
						},
						{
							key: 'companyRepresentative.contact.email',
							type: 'email',
							className: 'col-xs-12 col-sm-12 col-md-6 col-lg-6 col-xl-6',
							templateOptions: {
								label: 'eMail de Contato',
								type: 'text',
								required: true,
							}
						},
						{
							key: 'companyRepresentative.address.postalCode',
							type: 'mask-pattern',
							className: 'col-12 postal-code',
							templateOptions: {
								label: 'CEP',
								type: 'text',
								mask: '99 999 999',
								required: true
							},
							watcher: {
								listener: function (field, newValue, oldValue, scope) {
									if (!newValue || newValue === oldValue || newValue.length !== 10) return;
									premiosFansService.cep({
										data: { cep: newValue },
										success: response => {
											if (response.errors) return;
											scope.model.companyRepresentative.address.publicNameStreet = response.street || null;
											scope.model.companyRepresentative.address.district = response.neighborhood || null;
											scope.model.companyRepresentative.address.city = response.city || null;
											scope.model.companyRepresentative.address.state = response.state || null;
										}
									})
								}
							}
						},
						{
							key: 'companyRepresentative.address.publicNameStreet',
							templateOptions: {
								label: 'Rua, Avenida, Quadra, etc',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-8'
						},
						{
							key: 'companyRepresentative.address.numberHome',
							templateOptions: {
								label: 'Número',
								type: 'text',
								required: true,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-4'
						},
						{
							key: 'companyRepresentative.address.district',
							templateOptions: {
								label: 'Bairro',
								type: 'text',
								required: true,
								maxlength: 64
							},
							type: 'input',
							className: 'col-12'
						},
						{
							key: 'companyRepresentative.address.city',
							templateOptions: {
								label: 'Cidade',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							type: 'input',
							className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-8'
						},
						{
							key: 'companyRepresentative.address.state',
							type: 'ng-selector-estado',
							templateOptions: {
								label: 'Estado',
								type: 'text',
								required: true,
								minlength: 3,
								maxlength: 64
							},
							className: 'col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-4'
						},
						{
							key: 'companyRepresentative.address.complement',
							templateOptions: {
								label: 'Complemento',
								type: 'text',
								maxlength: 64
							},
							type: 'input',
							className: 'col-12'
						}
					],
					form: null
				},
			};
		}

		const loadConta = idConta => {
			collectionContas.get(idConta)

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

						loadConta($scope.idConta);
					} else {
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
