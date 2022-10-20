
const ngModule = angular.module('directives.dashboard-rh.block-pagamentos', [])

	.controller('dashboardRhBlockPagamentosController',
		function (
			$scope
		) {

			$scope.links = [
				{
					label: "Ver Lotes de Pagamento",
					help: "Acompanhe e libere lotes de pagamento já solicitados.",
					icon: "far fa-envelope"
				},
				{
					label: "Criar novo Lote de Pagamentos",
					help: "Prepare um novo lote para pagamentos de funcinários, adicionando os valores manualmente ou importando de uma planilha do Excel.",
					icon: "fas fa-money-check"
				}
			];

			$scope.init = _ => {

				var areaChartData = {
					labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
					datasets: [
						{
							label: 'Não processados',
							backgroundColor: 'rgba(60,141,188,0.9)',
							borderColor: 'rgba(60,141,188,0.8)',
							pointRadius: false,
							pointColor: '#3b8bba',
							pointStrokeColor: 'rgba(60,141,188,1)',
							pointHighlightFill: '#fff',
							pointHighlightStroke: 'rgba(60,141,188,1)',
							data: [28, 48, 40, 19, 86, 27, 90]
						},
						{
							label: 'Processados',
							backgroundColor: 'rgba(210, 214, 222, 1)',
							borderColor: 'rgba(210, 214, 222, 1)',
							pointRadius: false,
							pointColor: 'rgba(210, 214, 222, 1)',
							pointStrokeColor: '#c1c7d1',
							pointHighlightFill: '#fff',
							pointHighlightStroke: 'rgba(220,220,220,1)',
							data: [65, 59, 80, 81, 56, 55, 40]
						},
					]
				}

				var barChartData = $.extend(true, {}, areaChartData);
				var temp0 = areaChartData.datasets[0];
				var temp1 = areaChartData.datasets[1];
				barChartData.datasets[0] = temp1;
				barChartData.datasets[1] = temp0;

				var stackedBarChartCanvas = $('#stackedBarChart').get(0).getContext('2d');
				var stackedBarChartData = $.extend(true, {}, barChartData);

				var stackedBarChartOptions = {
					responsive: true,
					maintainAspectRatio: false,
					scales: {
						xAxes: [{
							stacked: true,
						}],
						yAxes: [{
							stacked: true
						}]
					}
				};

				new Chart(stackedBarChartCanvas, {
					type: 'bar',
					data: stackedBarChartData,
					options: stackedBarChartOptions
				})

			}

		})

	.directive('dashboardRhBlockPagamentos', function () {
		return {
			restrict: 'E',
			controller: 'dashboardRhBlockPagamentosController',
			link: function (scope) {
				scope.init();
			},
			scope: true,
			templateUrl: 'dashboard-rh/directives/block-pagamentos/block-pagamentos.html',
		};
	});

export default ngModule;
