
const ngModule = angular.module('directives.block-endereco', [])

	.controller('blockEnderecoController',
		function (
			$scope,
			globalFactory,
			utilsService
		) {

			var fields = [
				{
					key: 'cep',
					type: 'mask-pattern',
					className: 'col-12 cep',
					templateOptions: {
						label: 'CEP',
						type: 'text',
						mask: '99 999 999',
						required: true
					},
					watcher: {
						listener: function (field, newValue, oldValue, scope) {
							loadCep(newValue, oldValue, scope);
						}
					}
				},
				{
					key: 'rua',
					templateOptions: {
						label: 'Rua, Avenida, Quadra, etc',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					data: { cepField: 'logradouro' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xl-8',
				},
				{
					key: 'numero',
					templateOptions: {
						label: 'Número',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
				},
				{
					key: 'bairro',
					templateOptions: {
						label: 'Bairro',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					data: { cepField: 'bairro' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
				},
				{
					key: 'cidade',
					templateOptions: {
						label: 'Cidade',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					data: { cepField: 'cidade' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
				},
				{
					key: 'estado',
					templateOptions: {
						label: 'Estado',
						type: 'text',
						required: true
					},
					data: { cepField: 'estado' },
					type: 'ng-selector-estado',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-4 col-xl-4',
				},
				{
					key: 'complemento',
					templateOptions: {
						label: 'Complemento (nº da casa/apartamento, referências, etc)',
						type: 'text',
						required: false,
						minlength: 3,
						maxlength: 64
					},
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
				}
			];

			const loadCep = (cep, oldCep, scope) => {

				if (cep === oldCep) { return null; }

				cep = globalFactory.onlyNumbers(cep);

				if (!cep || cep.length !== 8) { return; }

				utilsService.getCep({
					cep: cep,
					success: data => {
						scope.fields.forEach(f => {
							if (f.data.cepField) {
								scope.model[f.key] = data[f.data.cepField] || null;
							}
						})
					}
				})

			}

			if ($scope.prefixo) {
				fields.map(f => {
					f.key = $scope.prefixo + f.key;
				})
			}

			$scope.fields = fields;

		}
	)

	.directive('blockEndereco', function () {
		return {
			restrict: 'E',
			templateUrl: 'block-endereco/block-endereco.html',
			controller: 'blockEnderecoController',
			scope: {
				ngModel: '=',
				prefixo: '@'
			}
		};
	});

export default ngModule;
