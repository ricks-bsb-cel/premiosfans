'use strict';

import config from './importacao-funcionarios.config';
import { Semaphore } from "async-mutex";

const ngModule = angular.module('views.folha.importacao-funcionarios', [
])
	.config(config)

	.controller('viewFolhaImportacaoFuncionariosController', function (
		$scope,
		alertFactory,
		blockUiFactory,
		$timeout,
		$window,
		globalFactory,
		folhaService
	) {

		$scope.ready = false;
		$scope.xlsxFile = null;
		$scope.showColumnsCard = true;

		$scope.pages = [];

		$scope.fileConfig = {
			file: null,
			page: null,
			columns: [],
			data: [],
			zoeColumns: [
				{ value: 'nan', label: '* Não Utilizado *' },
				{ value: 'cpf', label: 'CPF' },
				{ value: 'nome', label: 'Nome' },
				{ value: 'celular', label: 'Celular' },
				{ value: 'email', label: 'Email' },
			],
			status: {
				validos: 0,
				invalidos: 0
			},
			errors: {
				cpf: 0,
				nome: 0,
				celular: 0,
				email: 0
			},
			filters: {
				showValidos: true,
				showInvalidos: true
			}
		}

		let sheetResult = null;

		const init = _ => {
			$scope.ready = true;
		}

		let chartStatusCanvas,
			chartErrorsCanvas,
			showPieCharts = _ => {

				if (chartStatusCanvas) {
					chartStatusCanvas.data.datasets[0].data = [
						$scope.fileConfig.status.validos,
						$scope.fileConfig.status.invalidos
					];
					chartStatusCanvas.update();
				} else {
					chartStatusCanvas = new Chart($('#pieChartStatus').get(0).getContext('2d'), {
						type: 'doughnut',
						data: {
							labels: ['Válidos', 'Inválidos'],
							datasets: [
								{
									data: [
										$scope.fileConfig.status.validos,
										$scope.fileConfig.status.invalidos
									],
									backgroundColor: ['#28a745', '#dc3545']
								}
							]
						},
						options: {
							responsive: true,
							maintainAspectRatio: false,
							plugins: {
								legend: {
									display: true,
									position: 'right',
									labels: {
										boxWidth: 10,
										boxHeight: 10,
										font: { size: 13 },
										generateLabels: (chart) => {
											const datasets = chart.data.datasets;
											return datasets[0].data.map((data, i) => ({
												text: `${chart.data.labels[i]} (${data})`,
												fillStyle: datasets[0].backgroundColor[i]
											}))
										}
									}
								}
							}
						}
					});
				}

				if (chartErrorsCanvas) {
					chartErrorsCanvas.data.datasets[0].data = [
						$scope.fileConfig.errors.cpf,
						$scope.fileConfig.errors.nome,
						$scope.fileConfig.errors.celular,
						$scope.fileConfig.errors.email
					];
					chartErrorsCanvas.update();
				} else {
					chartErrorsCanvas = new Chart($('#pieChartErros').get(0).getContext('2d'), {
						type: 'doughnut',
						data: {
							labels: ['CPF', 'Nome', 'Celular', 'eMail'],
							datasets: [
								{
									data: [$scope.fileConfig.errors.cpf, $scope.fileConfig.errors.nome, $scope.fileConfig.errors.celular, $scope.fileConfig.errors.email],
									backgroundColor: ['#28a745', '#dc3545', '#007bff', '#ffc107']
								}
							]
						},
						options: {
							responsive: true,
							maintainAspectRatio: false,
							plugins: {
								legend: {
									display: true,
									position: 'right',
									labels: {
										boxWidth: 10,
										boxHeight: 10,
										font: { size: 13 },
										generateLabels: (chart) => {
											const datasets = chart.data.datasets;
											return datasets[0].data.map((data, i) => ({
												text: `${chart.data.labels[i]} (${data})`,
												fillStyle: datasets[0].backgroundColor[i]
											}))
										}
									}
								}
							}
						}
					});
				}

			}

		$scope.fileSelected = e => {
			$scope.fileConfig.file = e.target.files[0].name;
			$scope.showColumnsCard = true;
			$timeout(_ => {
				$scope.getFile();
			}, 500)
		}

		$scope.getFile = function () {

			var file = document.getElementById("xlsxFile").files[0];

			$scope.fileConfig.page = null;
			$scope.fileConfig.columns = [];
			$scope.fileConfig.data = [];

			if (!file) {
				return;
			}

			blockUiFactory.start();

			file.arrayBuffer().then(data => {

				// https://github.com/SheetJS/sheetjs
				const workbook = XLSX.read(data);

				var result = {};

				workbook.SheetNames.forEach(function (sheetName) {
					var roa = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { header: 1 });
					if (roa.length) { result[sheetName] = roa };
				});

				sheetResult = result;

				blockUiFactory.stop();

				loadSheetPages();

			})

		};

		const loadSheetPages = _ => {
			$scope.pages = [];

			Object.keys(sheetResult).forEach(f => {
				$timeout(_ => {
					$scope.pages.push(f);
				})
			})
		}

		$scope.isInvalid = campoZoepay => {
			if (!campoZoepay || campoZoepay === 'nan') {
				return false;
			}

			return $scope.fileConfig.columns.filter(f => {
				return f.campoZoepay === campoZoepay;
			}).length > 1;
		}

		$scope.validate = _ => {

			//#region * Verifica se a coluna CPF foi informada
			if ($scope.fileConfig.columns.filter(f => { return f.campoZoepay === 'cpf' }).length === 0) {
				alertFactory.error('A coluna que informa o CPF do funcionário deve ser definida.');
				return;
			}
			//#endregion

			//#region * Verifica se não existe duplicidades de campos
			let existeDuplicidade = false;

			$scope.fileConfig.columns.forEach(c => {
				if (!existeDuplicidade && c.campoZoepay !== 'nan') {
					existeDuplicidade = $scope.fileConfig.columns.filter(f => { return f.campoZoepay === c.campoZoepay; }).length > 1;
				}
			})

			if (existeDuplicidade) {
				alertFactory.error('Existem uma ou mais colunas apontando para o mesmo campo.');
				return;
			}
			//#endregion

			blockUiFactory.start(_ => {

				/*
				const percentCenter = document.getElementById("percent-center");
				percentCenter.style.display = "initial";
				*/

				$scope.fileConfig.data = [];
				$scope.fileConfig.status = { validos: 0, invalidos: 0 };
				$scope.fileConfig.errors = { cpf: 0, nome: 0, celular: 0, email: 0 };

				sheetResult[$scope.fileConfig.page].forEach((l, p) => {

					/*
					let value = Math.round((p * 100.0) / sheetResult[$scope.fileConfig.page].length);
					value = Math.round(value).toString() + '%';
	
					if (percentCenter.innerHTML !== value) {
						percentCenter.innerHTML = value;
						console.info('percentCenter.innerHTML', percentCenter.innerHTML);
					}
					*/

					if (l.length && p > 0) {

						let d = {
							isValid: true
						};

						$scope.fileConfig.columns.forEach((c, i) => {
							if (c.campoZoepay !== 'nan') {
								d[c.campoZoepay] = l[i];
							}
						})

						// Valida e Formata CPF
						d.cpf = d.cpf.toString();
						d.cpf_isValid = globalFactory.isCPFValido(d.cpf);

						if (d.cpf_isValid) {
							d.cpf_formatted = globalFactory.formatCpf(d.cpf);
						}

						$scope.fileConfig.errors.cpf += (d.cpf_isValid ? 0 : 1);

						if (d.isValid && !d.cpf_isValid) { d.isValid = false; }

						// Valida Nome
						if (d.nome) {
							d.nome = d.nome.toString().trim();
							d.nome_isValid = (globalFactory.onlyNumbers(d.nome).length === 0);
							$scope.fileConfig.errors.nome += (d.nome_isValid ? 0 : 1);
							if (d.isValid && !d.nome_isValid) { d.isValid = false; }
						}

						// Valida e Formata o Celular
						if (d.celular) {
							d.celular = d.celular.toString().trim();
							d.celular_isValid = (globalFactory.onlyNumbers(d.celular).length === 11);
							if (d.celular_isValid) {
								d.celular_formatted = globalFactory.formatPhoneNumber(d.celular);
							}
							$scope.fileConfig.errors.celular += (d.celular_isValid ? 0 : 1);
							if (d.isValid && !d.celular_isValid) { d.isValid = false; }
						}

						// Valida o email
						if (d.email) {
							d.email = d.email.toString().trim().toLowerCase();
							d.email_isValid = (d.email ? globalFactory.emailIsValid(d.email) : true);
							$scope.fileConfig.errors.email += (d.email_isValid ? 0 : 1);
							if (d.isValid && !d.email_isValid) { d.isValid = false; }
						}

						d.isInvalid = !d.isValid;

						$scope.fileConfig.status.validos += (d.isValid ? 1 : 0);
						$scope.fileConfig.status.invalidos += (d.isValid ? 0 : 1);

						$scope.fileConfig.data.push(d);
					}

				})

				showPieCharts();

				/*
				percentCenter.style.display = "hide";
				*/
				$scope.showColumnsCard = false;

				blockUiFactory.stop();

			});
		}

		$scope.getData = () => {
			if ($scope.fileConfig.filters.showValidos && $scope.fileConfig.filters.showInvalidos) {
				return $scope.fileConfig.data;
			} else if ($scope.fileConfig.filters.showValidos && !$scope.fileConfig.filters.showInvalidos) {
				return $scope.fileConfig.data.filter(f => { return f.isValid; });
			} else if (!$scope.fileConfig.filters.showValidos && $scope.fileConfig.filters.showInvalidos) {
				return $scope.fileConfig.data.filter(f => { return !f.isValid; });
			} else {
				$scope.fileConfig.filters.showValidos = true;
				$scope.fileConfig.filters.showInvalidos = true;
				return $scope.fileConfig.data;
			}
		}

		$scope.dataFilter = status => {
			return status === $scope.fileConfig.showValidos || stauts === $scope.fileConfig.showInvalidos;
		}

		$scope.linha = (c, i) => {
			if (sheetResult[$scope.fileConfig.page][i]) {
				return sheetResult[$scope.fileConfig.page][i][c] || null;
			} else {
				return null;
			}
		}

		$scope.pageSelected = _ => {
			const columns = sheetResult[$scope.fileConfig.page][0];
			$scope.fileConfig.columns = [];
			columns.forEach(c => {
				$scope.fileConfig.columns.push({
					campoPlanilha: c,
					campoZoepay: 'nan'
				});
			})
		}

		$scope.send = _ => {
			alertFactory.yesno('Iniciar importação do arquivo?').then(_ => {
				(async () => {
					let toSend = $scope.fileConfig.data.filter(f => { return f.isValid; });
					const qtdTotal = toSend.length;
					const semaphore = new Semaphore(32);

					blockUiFactory.start();
					blockUiFactory.percentStart();

					toSend.forEach(async (item, idx) => {

						const [value, release] = await semaphore.acquire();

						try {
							await folhaService.sendAsyncFuncionario(item);
						}
						catch (e) {
							console.log(e)
						}
						finally {
							blockUiFactory.percent(idx, qtdTotal);
							if (qtdTotal === (idx + 1)) {
								blockUiFactory.stop();
							}
							release();
						}
					})
				})();
			})
		}

		$scope.$on('$viewContentLoaded', function () {
			if ($window.File && $window.FileReader && $window.FileList && $window.Blob) {
				init();
			} else {
				alert('The File APIs are not fully supported in this browser.');
			}
		});

	});


export default ngModule;
