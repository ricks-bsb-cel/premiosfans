'use strict';

import viewSplash from './splash/splash';
import viewIndex from './index/index';
import viewConteudo from './conteudo/conteudo';

import viewAberturaContaSwpPJ from './abertura-conta-swp-pj/abertura-conta-swp-pj';

let ngModule = angular.module('views', [
	viewSplash.name,
	viewIndex.name,
	viewConteudo.name,

	viewAberturaContaSwpPJ.name	
]);

export default ngModule;
