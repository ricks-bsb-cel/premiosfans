'use strict';

import Swiper, { Navigation, Pagination } from 'swiper';

const ngModule = angular.module('directives.abrir-conta-pj-block', [])

	.controller('abrirContaPJController',
		function (
			$scope,
			$timeout,
			userService,
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
			};
			$scope.pages = null;

			$scope.phoneAuthDelegate = {};

			$scope.enviar = _ => {

				saveData();

				appAuthHelper.initAppUser(
					$scope.data.cpf,
					$scope.data.celular,
					true
				)

					.then(_ => {

						alertFactory.success('Sua conta foi solicitada com sucesso. Acompanhe a abertura aqui pelo App!')
							.then(_ => {
								$timeout(_ => {
									$location.path('/splash');
									$location.replace();
									// Foda-se... tô cansado...
									$timeout(_ => { window.location.reload() });
								})
							})

					})

					.catch(e => {
						console.error(e);
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

				$scope.data = {};

				return null;
			}

			/*
			const initOpenAccount = _ => {
				return new Promise((resolve, reject) => {
					getCurrentUser()
						.then(user => {
							currentUser = user;
							return appDatabaseHelper.once(`/zoeAccount/${currentUser.uid}/pj`);
						})
						.then(data => {
							$scope.data = data || {};
							return resolve();
						})
						.catch(e => {
							console.error(e);
							return reject(e);
						})
				})
			}
			*/

			$scope.htmlBlockDelegate = {
				ready: data => {
					const f = $scope.pages.findIndex(f => { return f.htmlBlock === data.sigla; });
					if (f >= 0) { $scope.pages[f].ready = true; }
					$timeout(_ => {
						$scope.swiper.update();
					})
				}
			}

			const loadCep = cep => {
				return new Promise(resolve => {

					cep = globalFactory.onlyNumbers(cep);

					if (!cep || cep.length !== 8) { return; }

					utilsService.getCep({
						cep: cep,
						success: data => {
							$scope.data.logradouro = data.logradouro;
							$scope.data.bairro = data.bairro;
							$scope.data.cidade = data.cidade;
							$scope.data.uf = data.estado;

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

				appDatabaseHelper.set(path, $scope.data);
			}

			const initForms = _ => {
				$scope.pages = [
					{
						htmlBlock: "app-folha-abertura-conta-pj-boasvindas"
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-empresa-cnpj",
						fields: [
							{
								key: 'empresa_cnpj',
								templateOptions: {
									required: true
								},
								type: 'cnpj'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {
								if (!$scope.data.empresa_cnpj) {
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
						fields: [
							{
								key: 'empresa_nome',
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
								key: 'empresa_nomeFantasia',
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
								if (!$scope.data.empresa_nome || $scope.data.empresa_nome <= 3 || !$scope.data.empresa_nomeFantasia || $scope.data.empresa_nomeFantasia <= 3) {
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
						fields: [
							{
								key: 'dtAbertura',
								type: 'data',
								templateOptions: {
									required: true
								}
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.dtAbertura) {
									setErrorMessage(currentIndex, 'Informe uma data de abertura válida');
									return reject();
								}

								if (!globalFactory.isValidDtNascimento($scope.data.dtAbertura)) {
									setErrorMessage(currentIndex, 'A idade deve ser entre 16 e 120 anos');
									return reject();
								}

								setErrorMessage(currentIndex);
								
								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-cpf",
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

								if (!$scope.data.cpf) {
									setErrorMessage(currentIndex, 'Informe o seu CPF corretamente');
									return reject();
								}

								return resolve();

								/*
								userService.checkCpfAberturaConta($scope.data.cpf, result => {
									if (result.error) {
										alertFactory.success(result.msg).then(_ => {
											$location.path('/splash');
											$location.replace();
										})

										return;
									}
									setErrorMessage(currentIndex);
									return resolve();
								})
								*/

							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-nome",
						fields: [
							{
								key: 'nome',
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

								if (!$scope.data.nome || $scope.data.nome <= 3) {
									setErrorMessage(currentIndex, 'Informe o seu Nome completo');
									return reject();
								}

								setErrorMessage(currentIndex);
								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-celular",
						fields: [
							{
								key: 'celular',
								templateOptions: {
									type: 'text',
									required: true
								},
								type: 'celular'
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.celular) {
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

								if (!$scope.data.email || !globalFactory.emailIsValid($scope.data.email)) {
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
						fields: [
							{
								key: 'dtNascimento',
								type: 'data',
								templateOptions: {
									required: true
								}
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.dtNascimento) {
									setErrorMessage(currentIndex, 'Informe uma data de nascimento válida');
									return reject();
								}

								if (!globalFactory.isValidDtNascimento($scope.data.dtNascimento)) {
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
						tipo: 'cep',
						fields: [
							{
								key: 'cep',
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

								if (!$scope.data.cep) {
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
						fields: [
							{
								key: 'logradouro',
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
								key: 'numero',
								templateOptions: {
									label: 'Número',
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							}
							,
							{
								key: 'bairro',
								templateOptions: {
									label: 'Bairro',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							},
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-responsavel-endereco-cidade-estado",
						fields: [
							{
								key: 'cidade',
								templateOptions: {
									label: 'Cidade',
									type: 'text',
									maxlength: 128,
									required: true
								},
								type: 'input'
							},
							{
								key: 'uf',
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
						fields: [
							{
								key: 'complemento',
								templateOptions: {
									maxlength: 256
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pj-doc-frente",
						imageName: 'doc-frente',
						fields: [
							{
								key: 'imagem_doc_frente',
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
						imageName: 'doc-verso',
						fields: [
							{
								key: 'imagem_doc_verso',
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
						isImage: 'selfie',
						fields: [
							{
								key: 'imagem_doc_selfie',
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
									return loadCep($scope.data.cep);
								} else {
									return;
								}
							})

							.then(_ => {
								saveData();
								$scope.swiper.slideNext();
							})

							.catch(_ => { })

					} else {
						saveData();
						$scope.swiper.slideNext();
					}
				}

				$scope.ready = true;

				$timeout(_ => {
					waitUiFactory.hide()
				}, 500)

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
