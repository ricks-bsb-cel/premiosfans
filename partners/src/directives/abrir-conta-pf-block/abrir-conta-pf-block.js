'use strict';

import Swiper, { Navigation, Pagination } from 'swiper';

const ngModule = angular.module('directives.abrir-conta-pf-block', [])

	.controller('abrirContaPFController',
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

			let currentUser = null;

			$scope.swiper;
			$scope.ready = false;
			$scope.data = {};
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

			const initOpenAccount = _ => {
				return new Promise((resolve, reject) => {
					getCurrentUser()
						.then(user => {
							currentUser = user;
							return appDatabaseHelper.once(`/zoeAccount/${currentUser.uid}/pf`);
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

				const path = `/zoeAccount/${currentUser.uid}/pf`;

				$scope.data.dtInicio = $scope.data.dtInicio || appFirestoreHelper.currentTimestamp();
				$scope.data.dtUltimaEdicao = appFirestoreHelper.currentTimestamp();

				appDatabaseHelper.set(path, $scope.data);
			}

			const initForms = _ => {
				$scope.pages = [
					{
						htmlBlock: "app-folha-abertura-conta-pf-boasvindas"
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-cpf",
						tipo: 'cpf',
						fields: [
							{
								key: 'cpf',
								templateOptions: {
									required: false
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

							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-nome",
						fields: [
							{
								key: 'nome',
								templateOptions: {
									type: 'text',
									maxlength: 128
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
						htmlBlock: "app-folha-abertura-conta-pf-celular",
						fields: [
							{
								key: 'celular',
								templateOptions: {
									type: 'text',
									disabled: _ => { return $scope.data.semCelular; }
								},
								type: 'celular'
							},
							{
								key: 'semCelular',
								templateOptions: {
									type: 'text',
									title: 'Não tenho celular próprio'
								},
								defaultValue: false,
								type: 'custom-checkbox',
								watcher: {
									listener: function (field, newValue, oldValue, scope) {
										if (typeof newValue === 'boolean' && newValue) {
											$scope.data.celular = null;
										}
									}
								},
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.celular && !$scope.data.semCelular) {
									setErrorMessage(currentIndex, 'Informe um número de celular válido');
									return reject();
								}

								if ($scope.data.semCelular) {
									return resolve();
								}

								$scope.phoneAuthDelegate.continue = user => {
									currentUser = user;

									saveData();
									setErrorMessage(currentIndex);

									waitUiFactory.stop();

									return resolve();
								}

								saveData();

								if (!currentUser.isAnonymous && currentUser.phoneNumber.includes($scope.data.celular)) {
									return resolve();
								} else {
									$scope.phoneAuthDelegate.startValidation({
										celular: $scope.data.celular,
										celular_formatted: $scope.data.celular_formatted,
										cpf: $scope.data.cpf
									});
								}

							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-email",
						fields: [
							{
								key: 'email',
								templateOptions: {
									type: 'text',
									disabled: _ => { return $scope.data.semEmail; }
								},
								type: 'email',
								ngModelElAttrs: $scope.data.semEmail ? { disabled: 'true' } : {}
							},
							{
								key: 'semEmail',
								templateOptions: {
									type: 'text',
									title: 'Não tenho email próprio'
								},
								defaultValue: false,
								type: 'custom-checkbox',
								watcher: {
									listener: function (field, newValue, oldValue, scope) {
										if (typeof newValue === 'boolean' && newValue) {
											$scope.data.email = null;
										}
									}
								},
							}
						],
						validation: (currentIndex) => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.semEmail &&
									(
										!$scope.data.email ||
										!globalFactory.emailIsValid($scope.data.email)
									)
								) {
									setErrorMessage(currentIndex, 'Informe um email válido');
									return reject();
								}

								setErrorMessage(currentIndex);
								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-dtnascimento",
						fields: [
							{
								key: 'dtNascimento',
								type: 'data',
								templateOptions: {

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
						htmlBlock: "app-folha-abertura-conta-pf-endereco-cep",
						tipo: 'cep',
						fields: [
							{
								key: 'cep',
								templateOptions: {
									type: 'text',
									mask: '99 999 999'
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
						htmlBlock: "app-folha-abertura-conta-pf-endereco-logradouro",
						fields: [
							{
								key: 'logradouro',
								templateOptions: {
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-endereco-bairro",
						fields: [
							{
								key: 'bairro',
								templateOptions: {
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-endereco-numero",
						fields: [
							{
								key: 'numero',
								templateOptions: {
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-endereco-cidade-estado",
						fields: [
							{
								key: 'cidade',
								templateOptions: {
									label: 'Cidade',
									type: 'text',
									maxlength: 128
								},
								type: 'input'
							},
							{
								key: 'uf',
								templateOptions: {
									label: 'Estado',
									type: 'text'
								},
								type: 'ng-selector-estado'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-endereco-complemento",
						fields: [
							{
								key: 'complemento',
								templateOptions: {
									type: 'text',
									maxlength: 256
								},
								type: 'textarea'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-estado-civil",
						fields: [
							{
								key: 'estadoCivil',
								templateOptions: {
									label: '',
									required: false,
									options: [
										{
											id: 'solteiro',
											value: 'solteiro',
											label: 'Solteiro'
										},
										{
											id: 'casado',
											value: 'casado',
											label: 'Casado ou União Estável'
										},
										{
											id: 'separado',
											value: 'separado',
											label: 'Separado'
										},
										{
											id: 'divorciado',
											value: 'divorciado',
											label: 'Divorciado'
										},
										{
											id: 'viuvo',
											value: 'viuvo',
											label: 'Viúvo'
										},
										{
											id: 'enrolado',
											value: 'enrolado',
											label: 'Enrolado 😄'
										}
									]
								},
								type: 'radios'
							}
						],
						validation: currentIndex => {
							return new Promise((resolve, reject) => {

								if (!$scope.data.estadoCivil) {
									setErrorMessage(currentIndex, 'Informe o seu estado civil');
									return reject();
								}

								setErrorMessage(currentIndex);
								return resolve();
							})
						}
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-meio-pagamento",
						fields: [
							{
								key: 'meioPagamentoMaisUtilizado',
								templateOptions: {
									label: '',
									required: false,
									options: [
										{
											id: 'dinheiro',
											value: 'dinheiro',
											label: 'Dinheiro'
										},
										{
											id: 'pix',
											value: 'pix',
											label: 'PIX'
										},
										{
											id: 'debito',
											value: 'debito',
											label: 'Cartão de Débito'
										},
										{
											id: 'credito',
											value: 'credito',
											label: 'Cartão de Crédito'
										},
										{
											id: 'boleto',
											value: 'boleto',
											label: 'Boleto'
										}
									]
								},
								type: 'radios'
							}
						]
					},
					{
						htmlBlock: "app-folha-abertura-conta-pf-doc-frente",
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
											filename: `/zoeAccount/${currentUser.uid}/pf/doc-frente-${globalFactory.guid()}`
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
						htmlBlock: "app-folha-abertura-conta-pf-doc-verso",
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
											filename: `/zoeAccount/${currentUser.uid}/pf/doc-verso-${globalFactory.guid()}`
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
						htmlBlock: "app-folha-abertura-conta-pf-selfie",
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
											filename: `/zoeAccount/${currentUser.uid}/pf/selfie-${globalFactory.guid()}`
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
						htmlBlock: "app-folha-abertura-conta-pf-resumo",
						tipo: 'resumo',
						ready: true
					}

				];
			}

			const initSwiper = _ => {

				initForms();

				$scope.swiper = new Swiper('.abrir-conta-pf-block .swiper', {
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

	.directive('abrirContaPfBlock', function () {
		return {
			restrict: 'E',
			templateUrl: 'abrir-conta-pf-block/abrir-conta-pf-block.html',
			controller: 'abrirContaPFController',
			link: function (scope, element) {
				scope.init();
			}
		};
	});

export default ngModule;
