'use strict';

const endPoints = _ => {

	let host = '';

	let result = {
		apiConfig: host + '/api/v1/api-config',

		collections: {
			clientes: host + '/api/collections/v1/clientes'
		},

		campanhas: {
			addInfluencerToCampanha: host + '/api/eeb/v1/add-influencer-to-campanha'
		},

		clientes: {
			get: host + '/api/clientes/v1/get',
			findCliente: host + '/api/v1/clientes/find',
			checkLogin: host + '/api/v1/clientes/check-login',
			updateUserStats: host + '/api/v1/clientes/update-user-stats',
			fakeData: 'https://randomuser.me/api/?nat=BR,ES,AU,US&inc=name,phone,email'  // https://randomuser.me/documentation#format
		},

		contratos: {
			get: host + '/api/contratos/v1/get',
			save: host + '/api/eeb/v1/recebimento/contrato'
		},

		cobrancas: {
			create: host + '/api/cobrancas/v1/create'
		},

		auth: {
			getUserInfo: host + '/api/users/v1/user',
			setEmpresaUsuario: host + '/api/users/v1/empresa'
		},

		google: {
			autocomplete: host + '/api/v1/maps/place/autocomplete',
			details: host + '/api/v1/maps/place/details'
		},

		pixKeys: {
			refresh: host + '/api/services/v1/pixkeys/v1',
			create: host + '/api/services/v1/pixkeys/v1'
		},

		contas: {
			balance: host + '/api/services/v1/balance/v1',
			account: host + '/api/services/v1/account/v1'
		},

		transaction: {
			refresh: host + '/api/services/v1/transaction/v1'
		},

		folha: {
			funcionario: {
				set: host + '/api/collections/v1/funcionario/v1',
				sendAsync: host + '/api/services/v1/folha/v1/funcionario/v1'
			}
		},

		utils: {
			cep: host + '/api/utils/v1/cep'
		}

	}

	return result;
}

const ngModule = angular.module('config.api-urls', [])
	.value('URLs', endPoints());

export default ngModule;
