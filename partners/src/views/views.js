'use strict';

import viewSplash from './splash/splash';
import viewIndex from './index/index';
import viewIndexUser from './index-user/index-user';
import viewConteudo from './conteudo/conteudo';
import viewProfile from './profile/profile';
import viewProfileUserInfo from './profile-user-info/profile-user-info';

import viewAccountOpen from './account-open/account-open';
import viewAccountOpenUser from './account-open-user/account-open-user';
import viewAccountOpenCompany from './account-open-company/account-open-company';
import viewAccountOpenDocs from './account-open-docs/account-open-docs';
import viewAccountOpenSend from './account-open-send/account-open-send';
import viewAccountStatus from './account-status/account-status';
import viewAccountChooseType from './account-choose-type/account-choose-type';
import viewAccountInfo from './account-info/account-info';

import viewAberturaContaSwpPF from './abertura-conta-swp-pf/abertura-conta-swp-pf';
import viewAberturaContaSwpPJ from './abertura-conta-swp-pj/abertura-conta-swp-pj';
import viewSolicitarEmprestimoPF from './solicitar-emprestimo-pf/solicitar-emprestimo-pf';

let ngModule = angular.module('views', [
	viewSplash.name,
	viewIndex.name,
	viewIndexUser.name,
	viewConteudo.name,

	viewProfile.name,
	viewProfileUserInfo.name,

	viewAccountOpen.name,
	viewAccountOpenUser.name,
	viewAccountOpenCompany.name,
	viewAccountOpenDocs.name,
	viewAccountOpenSend.name,
	viewAccountChooseType.name,
	viewAccountInfo.name,

	viewAberturaContaSwpPF.name,
	viewAberturaContaSwpPJ.name,
	viewSolicitarEmprestimoPF.name,
	
	viewAccountStatus.name
]);

export default ngModule;
