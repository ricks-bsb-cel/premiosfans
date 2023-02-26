import angular from 'angular';
import 'angular-i18n/angular-locale_pt-br';

import ngRoute from 'angular-route';
import ngMessages from 'angular-messages';
// import ngAnimate from '../node_modules/angular-animate';
import ngCookies from 'angular-cookies';
import ngTouch from 'angular-touch';
import angularInputMasks from 'angular-input-masks';

import 'ng-mask';
let ngMask = 'ngMask';

import 'angular-selector/dist/angular-selector';
let ngSelector = 'selector';

import angularCache from 'angular-cache';
import toastr from 'angular-toastr';
import ngFilter from 'angular-filter';

// https://github.com/ghiden/angucomplete-alt
import 'angucomplete-alt';
let angucompleteAlt = 'angucomplete-alt';

// ui.sortable
import 'angular-ui-sortable';
let ngSortable = 'ui.sortable'

// https://www.npmjs.com/package/ui-bootstrap4
// https://angular-ui.github.io/bootstrap/
// import '../node_modules/ui-bootstrap4';
// let ngUiBootstrap = 'ui.bootstrap';

const ngModule = angular.module(
	'vendor',
	[
		ngRoute,
		ngMessages,
	//	ngAnimate,
		ngTouch,
		ngCookies,
		angularInputMasks,
		ngSortable,
		// ngUiBootstrap,
		ngMask,
		angularCache,
		angucompleteAlt,
		toastr,
		ngFilter,
		ngSelector
	]
);

export default ngModule;
