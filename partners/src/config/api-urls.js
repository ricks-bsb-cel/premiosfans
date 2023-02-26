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

			/*
			account: {
				details: `${endpoints.account}/user/details`,
				refresh: `${endpoints.account}/user/refresh`,
				init: `${endpoints.account}/user/init`,
				confirmEmailCode: `${endpoints.account}/user/email/code`,
				resendEmailCode: `${endpoints.account}/user/email/resend`

				check: `${endpoints.account}/check`,
				create: `${endpoints.account}/create`,
				sendCodeToEmail: `${endpoints.account}/sendcode/email`,
				confirmEmailCode: `${endpoints.account}/confirmcode/email`, // post
				status: `${endpoints.account}/status`,
				list: `${endpoints.account}/list`,
				init: `${endpoints.account}/init`,
				'details-pf': `${endpoints.account}/details/pf`,
				'details-pj': `${endpoints.account}/details/pj`,
				'status-details-pf': `${endpoints.account}/status/details/pf`,
				'status-details-pj': `${endpoints.account}/status/details/pj`
				
			}
			*/

		},

		utils: {
			getCep: endpoints.utils + '/v1/cep'
		}
	});

export default ngModule;
