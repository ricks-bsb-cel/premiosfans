'use strict';

const endpoints = {
	user: 'https://zoepay-57t7prxj.uc.gateway.dev/api/users/v1/user',
	account: 'https://zoepay-57t7prxj.uc.gateway.dev/api/users/v1/account',
	utils: 'https://zoepay-57t7prxj.uc.gateway.dev/api/utils',
}

const ngModule = angular.module('config.api-urls', [])

	.value('URLs', {
		user: {

			updateUserInfo: `${endpoints.user}/update`,
			appInit: `https://zoepay-57t7prxj.uc.gateway.dev/api/users/v1/appUser/init`,

			account: {
				refresh: `${endpoints.account}/user/refresh`,
				init: `${endpoints.account}/user/init`,
				emailCode: `${endpoints.account}/user/email/code`,
				emailResendCode: `${endpoints.account}/user/email/resend`,

				accountOpen: `${endpoints.account}/user/account/open`
			}
		},

		utils: {
			getCep: endpoints.utils + '/v1/cep'
		}
	});

export default ngModule;
