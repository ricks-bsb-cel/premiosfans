'use strict';

import viewSplash from './splash/splash';
import viewIndex from './index/index';
import viewIndexUser from './index-user/index-user';
import viewConteudo from './conteudo/conteudo';
import viewProfile from './profile/profile';
import viewProfileUserInfo from './profile-user-info/profile-user-info';

import viewAberturaContaSwpPF from './abertura-conta-swp-pf/abertura-conta-swp-pf';
import viewAberturaContaSwpPJ from './abertura-conta-swp-pj/abertura-conta-swp-pj';
import viewAberturaContaSwpInfluencer from './abertura-conta-swp-influencer/abertura-conta-swp-influencer';

let ngModule = angular.module('views', [
	viewSplash.name,
	viewIndex.name,
	viewIndexUser.name,
	viewConteudo.name,

	viewProfile.name,
	viewProfileUserInfo.name,

	viewAberturaContaSwpPF.name,
	viewAberturaContaSwpPJ.name,
	viewAberturaContaSwpInfluencer.name
]);

export default ngModule;
