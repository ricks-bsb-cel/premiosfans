let config = function (formlyConfigProvider) {

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

	/*
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
