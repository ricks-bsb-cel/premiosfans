let config = function (formlyConfigProvider) {

	formlyConfigProvider.setWrapper([
		{
			name: 'default',
			types: [
				'input',
				'celular',
				'cpf',
				'cpfcnpj',
				'cnpj',
				'email',
				'integer',
				'telefone',
				'data',
				'url',
				'ng-selector-estado'
			],
			templateUrl: 'formly-wrappers/default-wrapper.html'
		}
	]);


	/*

	formlyConfigProvider.extras.errorExistsAndShouldBeVisibleExpression = 'fc.$touched || form.$submitted';

	formlyConfigProvider.setType([
		
		{ 	// maskedInput
			name: 'maskedInput',
			extends: 'input',
			defaultOptions: {
				ngModelAttrs: {
					mask: { attribute: 'mask' },
					'false': { value: 'clean' }
				},
				validation: {
					messages: {
						mask: '"Valor inválido"'
					}
				}
			}
		}
	])

	formlyConfigProvider.setWrapper([
		{
			name: 'extras',
			types: [
				'input',
				'select',
				'textarea'
			],
			templateUrl: 'formly-wrappers/extras-wrapper.html'
		}
	]);
	*/

};

export default config;
