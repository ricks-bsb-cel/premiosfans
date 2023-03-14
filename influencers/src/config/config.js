'use strict';

import run from './run';
import apiUrls from './api-urls';

const ngModule = angular.module('config', [
	apiUrls.name
])
	.run(run)

	.value('globalParms', {
		appName: 'PremiosFans Partners',
		appUrl: 'https://zoepay.app',
		appVersion: '0.1.0',
		logoImg: '/adm/img/logo.png'
	})

	.filter('unsafe', function ($sce) {
		return $sce.trustAsHtml;
	})

	.filter('url', function () {
		return function (value, showHttp) {
			return (showHttp ? window.location.origin : window.location.host) + '/' + value;
		}
	})

	.filter('formatCNPJ', function (globalFactory) {
		return function (cnpj) {
			return globalFactory.formatCnpj(cnpj);
		}
	})

	.filter('formatCPF', function (globalFactory) {
		return function (cpf) {
			return globalFactory.formatCpf(cpf);
		}
	})

	.filter('capitalize', function () {
		return function (value) {
			if (!value) { return null; }
			const artigos = ['o', 'os', 'a', 'as', 'um', 'uns', 'uma', 'umas', 'a', 'ao', 'aos', 'à', 'às', 'de', 'do', 'dos', 'da', 'das', 'dum', 'duns', 'duma', 'dumas', 'em', 'no', 'nos', 'na', 'nas', 'num', 'nuns', 'numa', 'numas'];
			let result = '';
			value.split(' ').forEach(word => {
				word = word.trim().toLowerCase() + ' ';
				result += (artigos.includes(word) ? word : word.charAt(0).toUpperCase() + word.slice(1));
			})
			return result.trimEnd();
		}
	})

	.filter('estadoCivil', function () {
		return function (value) {
			const options = [
				{
					value: 'solteiro',
					label: 'Solteiro'
				},
				{
					value: 'casado',
					label: 'Casado ou União Estável'
				},
				{
					value: 'separado',
					label: 'Separado'
				},
				{
					value: 'divorciado',
					label: 'Divorciado'
				},
				{
					value: 'viuvo',
					label: 'Viuvo'
				},
				{
					value: 'enrolado',
					label: 'Enrolado 😄'
				}
			];
			const i = options.findIndex(f => { return f.value === value; });
			return i >= 0 ? options[i].label : null;
		}
	})

	.filter('unsafe', function ($sce) {
		return $sce.trustAsHtml;
	})

	.config(

		function (
			$routeProvider
		) {

			$routeProvider
				.otherwise({
					redirectTo: {
						path: '/splash/',
						label: 'splash'
					}
				});

		}
	)

	.config(['$qProvider', function ($qProvider) {
		$qProvider.errorOnUnhandledRejections(false);
	}]);

export default ngModule;
