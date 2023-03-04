'use strict';

import Swiper, { Navigation, Pagination } from 'swiper';

const ngModule = angular.module('directives.abrir-conta-pj-block', [])

	.controller('abrirContaPJController',
		function (
			$scope,
			$timeout,
			globalFactory,
			waitUiFactory,
			utilsService,
			appAuthHelper,
			appFirestoreHelper,
			appDatabaseHelper,
			alertFactory,
			$location
		) {

			const databaseKey = 'pedidosAberturaConta';

			let currentUser = null;

			$scope.swiper;
			$scope.ready = false;

			$scope.data = {
				encerrado: false,
				companyData: {},
				personalData: {},
				addressCompany: {},
				addressPersonal: {},
				images: {}
			};

			$scope.pages = null;

			$scope.phoneAuthDelegate = {};

			$scope.enviar = _ => {

				$scope.data.dtFinal = appFirestoreHelper.currentTimestamp();
				$scope.data.encerrado = true;

				saveData();

				alertFactory.success('Sua conta foi solicitada com sucesso. Acompanhe a abertura aqui pelo App!')
					.then(_ => {
						$timeout(_ => {
							$location.path('/splash');
							$location.replace();

							// Foda-se... tô cansado...
							$timeout(_ => { window.location.reload() });
						})
					})

			}

			const setErrorMessage = (activeIndex, message) => {
				$scope.pages[activeIndex].errorMessage = message || null;

				$timeout(_ => {
					$scope.swiper.update();
				})

				$timeout(_ => {
					$scope.pages[activeIndex].errorMessage = null;
					$scope.swiper.update();
				}, 5000)
			}

			const getCurrentUser = _ => {
				return new Promise((resolve, reject) => {
					if (appAuthHelper.currentUser) {
						return resolve(appAuthHelper.currentUser);
					} else {
						appAuthHelper.signInAnonymously()
							.then(currentUser => {
								return resolve(currentUser);
							})
							.catch(e => {
								return reject(e);
							})
					}
				})
			}

			async function initOpenAccount() {
				currentUser = await getCurrentUser();

				return null;
			}

			$scope.htmlBlockDelegate = {
				ready: data => {
					const f = $scope.pages.findIndex(f => { return f.htmlBlock === data.sigla; });

					if (f >= 0) { $scope.pages[f].ready = true; }

					$timeout(_ => {
						$scope.swiper.update();

						if (data.sigla === 'app-folha-abertura-conta-pj-boasvindas') {
							waitUiFactory.hide();
						}
					})

				}
			}

			const loadCep = (cep, obj) => {
				return new Promise(resolve => {

					cep = globalFactory.onlyNumbers(cep);

					if (!cep || cep.length !== 8) { return; }

					utilsService.getCep({
						cep: cep,
						success: data => {
							obj.street = data.logradouro;
							obj.district = data.bairro;
							obj.city = data.cidade;
							obj.state = data.estado;

							return resolve();
						},
						error: _ => {
							return resolve();
						}
					})
				})
			}

			const saveData = _ => {
				if (!currentUser || !$scope.data) { return; }

				const path = `/${databaseKey}/${currentUser.uid}/pj`;

				$scope.data.dtInicio = $scope.data.dtInicio || appFirestoreHelper.currentTimestamp();
				$scope.data.dtUltimaEdicao = appFirestoreHelper.currentTimestamp();

				console.info($scope.data);

				appDatabaseHelper.set(path, $scope.data);
			}

			const initForms = _ => {
				$scope.pages = [
					{
						htmlBlock: "app-folha-abertura-conta-pj-boasvindas"
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-cnpj",
						data: $scope.data.companyData,
						fields: [
							{
								key: 'cnpj',
								templateOptions: {
									required: true
								},
								type: 'cnpj'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {
								if (!$scope.data.companyData.cnpj) {
									setErrorMessage(currentIndex, 'Informe o seu CNPJ corretamente');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-nome",
						data: $scope.data.companyData,
						fields: [
							{
								key: 'companyName',
								templateOptions: {
									label: 'Nome',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input',
								className: 'mt-2'
							},
							{
								key: 'tradingName',
								templateOptions: {
									label: 'Nome Fantasia',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input',
								className: 'mt-2'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {
								if (
									!$scope.data.companyData.companyName ||
									$scope.data.companyData.companyName <= 3 ||
									!$scope.data.companyData.tradingName ||
									$scope.data.companyData.tradingName <= 3
								) {
									setErrorMessage(currentIndex, 'Informe o nome e nome de fantasia da empresa');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-dtabertura",
						data: $scope.data.companyData,
						fields: [
							{
								key: 'dateStartCompany',
								type: 'data',
								templateOptions: {
									required: true
								}
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.companyData.dateStartCompany) {
									setErrorMessage(currentIndex, 'Informe uma data de abertura válida');
									return reject();
								}

								if (!globalFactory.isValidDtNascimento($scope.data.companyData.dateStartCompany)) {
									setErrorMessage(currentIndex, 'A idade deve ser entre 16 e 120 anos');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},

					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-endereco-cep",
						data: $scope.data.addressCompany,
						tipo: 'cep',
						fields: [
							{
								key: 'postalCode',
								templateOptions: {
									type: 'text',
									mask: '99 999 999',
									required: true
								},
								type: 'mask-pattern'
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {
								if (!$scope.data.addressCompany.postalCode) {
									setErrorMessage(currentIndex, 'Informe um CEP válido');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-endereco-logradouro",
						data: $scope.data.addressCompany,
						fields: [
							{
								key: 'street',
								templateOptions: {
									label: 'Logradouro',
									type: 'text',
									maxlength: 128,
									required: true
								},
								className: 'mt-5',
								type: 'input'
							},
							{
								key: 'number',
								templateOptions: {
									label: 'Número',
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							},
							{
								key: 'district',
								templateOptions: {
									label: 'Bairro',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-endereco-cidade-estado",
						data: $scope.data.addressCompany,
						fields: [
							{
								key: 'city',
								templateOptions: {
									label: 'Cidade',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							},
							{
								key: 'state',
								templateOptions: {
									label: 'Estado',
									type: 'text',
									required: true
								},
								type: 'ng-selector-estado'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-endereco-complemento",
						data: $scope.data.addressCompany,
						fields: [
							{
								key: 'complement',
								templateOptions: {
									maxlength: 256
								},
								type: 'input'
							}
						]
					},

					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-cpf",
						data: $scope.data.personalData,
						fields: [
							{
								key: 'cpf',
								templateOptions: {
									required: true
								},
								type: 'cpf'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.personalData.cpf) {
									setErrorMessage(currentIndex, 'Informe o seu CPF corretamente');
									return reject();
								}

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-nome",
						data: $scope.data.personalData,
						fields: [
							{
								key: 'name',
								templateOptions: {
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {
								if (!$scope.data.personalData.name || $scope.data.personalData.name <= 3) {
									setErrorMessage(currentIndex, 'Informe o nome completo do responsável');
									return reject();
								}

								setErrorMessage(currentIndex);
								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-celular",
						data: $scope.data.personalData,
						fields: [
							{
								key: 'phone',
								templateOptions: {
									type: 'text',
									required: true
								},
								type: 'celular'
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.personalData.phone) {
									setErrorMessage(currentIndex, 'Informe um número de celular válido');
									return reject();
								}

								saveData();

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-email",
						data: $scope.data.personalData,
						fields: [
							{
								key: 'email',
								templateOptions: {
									type: 'text',
									required: true
								},
								type: 'email'
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.personalData.email || !globalFactory.emailIsValid($scope.data.personalData.email)) {
									setErrorMessage(currentIndex, 'Informe um email válido');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-dtnascimento",
						data: $scope.data.personalData,
						fields: [
							{
								key: 'birthdate',
								type: 'data',
								templateOptions: {
									required: true
								}
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.personalData.birthdate) {
									setErrorMessage(currentIndex, 'Informe uma data de nascimento válida');
									return reject();
								}

								if (!globalFactory.isValidDtNascimento($scope.data.personalData.birthdate)) {
									setErrorMessage(currentIndex, 'A idade deve ser entre 16 e 120 anos');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},

					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-endereco-cep",
						data: $scope.data.addressPersonal,
						tipo: 'cep',
						fields: [
							{
								key: 'postalCode',
								templateOptions: {
									type: 'text',
									mask: '99 999 999',
									required: true
								},
								type: 'mask-pattern'
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {
								if (!$scope.data.addressPersonal.postalCode) {
									setErrorMessage(currentIndex, 'Informe um CEP válido');
									return reject();
								}

								setErrorMessage(currentIndex);

								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-endereco-logradouro",
						data: $scope.data.addressPersonal,
						fields: [
							{
								key: 'street',
								templateOptions: {
									label: 'Logradouro',
									type: 'text',
									maxlength: 128,
									required: true
								},
								className: 'mt-5',
								type: 'input'
							},
							{
								key: 'number',
								templateOptions: {
									label: 'Número',
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							},
							{
								key: 'district',
								templateOptions: {
									label: 'Bairro',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-endereco-cidade-estado",
						data: $scope.data.addressPersonal,
						fields: [
							{
								key: 'city',
								templateOptions: {
									label: 'Cidade',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							},
							{
								key: 'state',
								templateOptions: {
									label: 'Estado',
									type: 'text',
									required: true
								},
								type: 'ng-selector-estado'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-endereco-complemento",
						data: $scope.data.addressPersonal,
						fields: [
							{
								key: 'complement',
								templateOptions: {
									maxlength: 256
								},
								type: 'input'
							}
						]
					},

					{
						htmlBlock: "app-folha-abertura-conta-pj-doc-frente",
						data: $scope.data.images,
						fields: [
							{
								key: 'documentFront',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '8:5',
										storage: {
											imageName: 'doc-frente',
											filename: `/${databaseKey}/${currentUser.uid}/pj/doc-frente-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: _ => { saveData(); }
								}
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-doc-verso",
						data: $scope.data.images,
						fields: [
							{
								key: 'documentBack',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '8:5',
										storage: {
											imageName: 'doc-verso',
											filename: `/${databaseKey}/${currentUser.uid}/pj/doc-verso-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: _ => { saveData(); }
								}
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-selfie",
						data: $scope.data.images,
						fields: [
							{
								key: 'documentFace',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '1:1',
										storage: {
											imageName: 'selfie',
											filename: `/${databaseKey}/${currentUser.uid}/pj/selfie-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: _ => { saveData(); }
								}
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-resumo",
						tipo: 'resumo',
						ready: true
					}

				];
			}

			const initSwiper = _ => {

				initForms();

				$scope.swiper = new Swiper('.abrir-conta-pj-block .swiper', {
					autoHeight: true,
					direction: 'horizontal',
					loop: false,
					allowTouchMove: false
				});

				$scope.prev = _ => {
					$scope.swiper.slidePrev();
				}

				$scope.next = _ => {
					const page = $scope.pages[$scope.swiper.activeIndex];

					if (page.form && typeof page.validation === 'function') {

						page.validation($scope.swiper.activeIndex, page)
							.then(_ => {
								if (page.tipo === 'cep') {
									return loadCep(page.data.postalCode, page.data);
								} else {
									return;
								}
							})
							.then(_ => {
								saveData();

								$scope.swiper.slideNext();
							});

					} else {
						saveData();

						$scope.swiper.slideNext();
					}
				}

				$scope.ready = true;

				/*
				$timeout(_ => {
					waitUiFactory.hide()
				}, 500)
				*/

			}

			$scope.init = _ => {
				appAuthHelper.ready()
					.then(_ => {
						return initOpenAccount();
					})
					.then(_ => {
						initSwiper();
					})
					.catch(e => {
						console.error(e);
					})
			}

		}
	)

	.directive('abrirContaPjBlock', function () {
		return {
			restrict: 'E',
			templateUrl: 'abrir-conta-pj-block/abrir-conta-pj-block.html',
			controller: 'abrirContaPJController',
			link: function (scope, element) {
				scope.init();
			}
		};
	});

export default ngModule;
