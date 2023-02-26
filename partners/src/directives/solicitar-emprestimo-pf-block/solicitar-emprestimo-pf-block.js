'use strict';

import Swiper, { Navigation, Pagination } from 'swiper';

const ngModule = angular.module('directives.solicitar-emprestimo-pf-block', [])

	.controller('solicitarEmprestimoPFController',
		function (
			$scope,
			$timeout,
			waitUiFactory,
			footerBarFactory
		) {

			$scope.swiper;
			$scope.ready = false;

			$scope.valorSimulacao = null;

			footerBarFactory.show();

			$scope.forms = {
				valor: {
					fields: [
						{
							key: 'valor',
							templateOptions: {
								label: 'Valor desejado',
								required: true
							},
							type: 'reais'
						}
					]
				}
			};

			$scope.htmlBlockDelegate = {
				ready: data => {
					$timeout(_ => {
						$scope.swiper.update();
					})
				}
			}

			$scope.simulacao = [];

			const applyMasks = _ => {
				var e = document.getElementById('valorDesejado');
				VMasker(e).maskNumber();
			}

			$scope.check = parcela => {
				$scope.simulacao.map(s => {
					s.checked = parcela.qtdParcelas === s.qtdParcelas;
				})
			}

			const simular = valor => {
				valor = parseFloat(valor);
				const qtdTotalParcelas = 8;
				const juros = 0.10;

				$scope.simulacao = [];

				for (let i = 1; i < qtdTotalParcelas; i++) {

					let opcao = {
						qtdParcelas: i,
						valor: (valor / i) + (valor * juros)
					};

					opcao.valor = opcao.valor.toFixed(0);

					$scope.simulacao.push(opcao);
				}

			}

			const initSwiper = _ => {

				$scope.swiper = new Swiper('.solicitar-emprestimo-pf-block .swiper', {
					autoHeight: true,
					direction: 'horizontal',
					loop: false,
					allowTouchMove: false
				});

				$scope.prev = _ => {
					$scope.swiper.slidePrev();
				}

				$scope.next = _ => {
					simular($scope.valorSimulacao);
					$scope.swiper.slideNext();
				}

				$timeout(_ => {
					$scope.swiper.update();
					$scope.ready = true;
					applyMasks();
					waitUiFactory.hide()
				}, 500)

			}

			$scope.init = _ => {

				initSwiper();

			}

		}

	)

	.directive('solicitarEmprestimoPfBlock', function () {
		return {
			restrict: 'E',
			templateUrl: 'solicitar-emprestimo-pf-block/solicitar-emprestimo-pf-block.html',
			controller: 'solicitarEmprestimoPFController',
			link: function (scope, element) {
				scope.init();
			}
		};
	});

export default ngModule;
