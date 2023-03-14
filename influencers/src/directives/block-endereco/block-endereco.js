const ngModule = angular.module('directives.block-endereco', [])

	.controller('blockEnderecoController',
		function (
			$scope,
			globalFactory,
			utilsService
		) {

			$scope.fields = null;
			$scope.prefix = $scope.prefix || '';

			$scope.fields = [
				{
					key: $scope.prefix + 'cep',
					type: 'mask-pattern',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12 cep',
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
					},
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'rua',
					templateOptions: {
						label: 'Rua, Avenida, Quadra, etc',
						type: 'text',
						required: true,
						maxlength: 32
					},
					data: { cepField: 'logradouro' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'numero',
					templateOptions: {
						label: 'Número',
						type: 'text',
						required: true,
						maxlength: 64
					},
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'bairro',
					templateOptions: {
						label: 'Bairro',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					data: { cepField: 'bairro' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'cidade',
					templateOptions: {
						label: 'Cidade',
						type: 'text',
						required: true,
						minlength: 3,
						maxlength: 64
					},
					data: { cepField: 'cidade' },
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'estado',
					templateOptions: {
						label: 'Estado',
						type: 'text',
						required: true
					},
					data: { cepField: 'estado' },
					type: 'ng-selector-estado',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-3 col-xl-3',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
				},
				{
					key: $scope.prefix + 'complemento',
					templateOptions: {
						label: 'Complemento',
						type: 'text',
						required: false,
						maxlength: 64
					},
					type: 'input',
					className: 'col-xs-12 col-sm-12 col-md-12 col-lg-12 col-xl-12',
					ngModelElAttrs: $scope.disabled ? { disabled: 'true' } : {}
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

		}
	)

	.directive('blockEndereco', function () {
		return {
			restrict: 'E',
			templateUrl: 'block-endereco/block-endereco.html',
			controller: 'blockEnderecoController',
			scope: {
				ngModel: '=',
				disabled: '=',
				prefix: '@?'
			}
		};
	});

export default ngModule;
