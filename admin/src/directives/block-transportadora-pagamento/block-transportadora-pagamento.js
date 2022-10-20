
const ngModule = angular.module('directives.block-transportadora-pagamento', [])

	.controller('blockTransportadoraPagamentoController',
		function (
			$scope
		) {

			var fields = [
				{
					key: 'paymentTransport.boleto',
					type: 'select',
					defaultValue: 'conpay',
					templateOptions: {
						label: 'Boleto',
						options: [
							{ name: 'ConPay', value: 'conpay' }
						]
					},
                    className: 'col-3'
				},
				{
					key: 'paymentTransport.credito',
					type: 'select',
					defaultValue: 'conpay',
					templateOptions: {
						label: 'Cartão de Crédito',
						options: [
							{ name: 'ConPay', value: 'conpay' }
						]
					},
                    className: 'col-3'
				},
				{
					key: 'paymentTransport.link',
					type: 'select',
					defaultValue: 'conpay',
					templateOptions: {
						label: 'Link de Pagamento',
						options: [
							{ name: 'ConPay', value: 'conpay' }
						]
					},
                    className: 'col-3'
				},
				{
					key: 'paymentTransport.pix',
					type: 'select',
					defaultValue: 'conpay',
					templateOptions: {
						label: 'Pix',
						options: [
							{ name: 'ConPay', value: 'conpay' }
						]
					},
                    className: 'col-3'
				},
			];

			$scope.fields = fields;

		}
	)

	.directive('blockTransportadoraPagamento', function () {
		return {
			restrict: 'E',
			templateUrl: 'block-transportadora-pagamento/block-transportadora-pagamento.html',
			controller: 'blockTransportadoraPagamentoController',
			scope: {
				model: '='
			}
		};
	});

export default ngModule;
