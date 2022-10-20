
const ngModule = angular.module('directives.dashboard-rh.block-funcionarios', [])

	.controller('dashboardRhBlockFuncionariosController',
		function (
			$scope
		) {

			$scope.pieData = {};

			$scope.links = [
				{
					label: "Ver Cadastro",
					help: "Procure e atualize os dados de Funcionários já cadastrados."
				},
				{
					label: "Importar Planilha",
					help: "Autorize seus funcionários à abrir contas no Zoepay importando um planilhas do Excel."
				},
				{
					label: "Cadastrar Manualmente",
					help: "Autorize um o cadastro de um novo funcionário manualmente."
				},

				{
					label: "Desligamento de Funcionários",
					help: "Desative funcionários desligados, evitando assim pagamentos incorretos."
				},
			];

			$scope.init = _ => {

				const pieChartCanvas = $('#pieChartFuncionarios').get(0).getContext('2d');

				$scope.pieData = {
					labels: [
						'Ativos',
						'Sem conta',
						'Desligados'
					],
					datasets: [
						{
							data: [250, 120, 15],
							backgroundColor: ['#28a745', '#dc3545', '#007bff']
						}
					]
				};

				const pieOptions = {
					legend: {
						display: false
					}
				};

				const pieChart = new Chart(pieChartCanvas, {
					type: 'doughnut',
					data: $scope.pieData,
					options: pieOptions
				});

			}

		})

	.directive('dashboardRhBlockFuncionarios', function () {
		return {
			restrict: 'E',
			controller: 'dashboardRhBlockFuncionariosController',
			link: function (scope) {
				scope.init();
			},
			scope: true,
			templateUrl: 'dashboard-rh/directives/block-funcionarios/block-funcionarios.html',
		};
	});

export default ngModule;
