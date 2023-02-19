import angular from '../node_modules/angular';
import '../node_modules/angular-i18n/angular-locale_pt-br';

import ngRoute from '../node_modules/angular-route';
import ngMessages from '../node_modules/angular-messages';
import ngAnimate from '../node_modules/angular-animate';
import ngCookies from '../node_modules/angular-cookies';
import ngTouch from '../node_modules/angular-touch';
import angularInputMasks from '../node_modules/angular-input-masks';

// https://angular-google-chart.github.io/angular-google-chart/
import '../node_modules/angular-google-chart';
let googlechart = 'googlechart';

import '../node_modules/ng-mask';
let ngMask = 'ngMask';

import '../node_modules/angular-selector/dist/angular-selector';
let ngSelector = 'selector';

import angularCache from '../node_modules/angular-cache';
import toastr from '../node_modules/angular-toastr';
import ngFilter from '../node_modules/angular-filter';

// https://github.com/ghiden/angucomplete-alt
import '../node_modules/angucomplete-alt';
let angucompleteAlt = 'angucomplete-alt';

// ui.sortable
import '../node_modules/angular-ui-sortable';
let ngSortable = 'ui.sortable'

// https://www.npmjs.com/package/ui-bootstrap4
// https://angular-ui.github.io/bootstrap/
import '../node_modules/ui-bootstrap4';
let ngUiBootstrap = 'ui.bootstrap';

// https://www.npmjs.com/package/angular-summernote
import '../node_modules/angular-summernote/dist/angular-summernote';
let ngSummernote = 'summernote';

// https://github.com/angular-slider/angularjs-slider
import '../node_modules/angularjs-slider/dist/rzslider';
let rzSlider = 'rzSlider';

// http://krispo.github.io/json-tree/
import '../node_modules/json-tree2';
let jsontree = 'json-tree';

import 'angular-tree-control';

const ngModule = angular.module(
	'vendor',
	[
		ngRoute,
		ngMessages,
		ngAnimate,
		ngTouch,
		ngCookies,
		angularInputMasks,
		ngSortable,
		ngUiBootstrap,
		ngMask,
		angularCache,
		angucompleteAlt,
		toastr,
		ngSummernote,
		ngFilter,
		googlechart,
		rzSlider,
		ngSelector,
		jsontree,
		'treeControl'
	]
);

export default ngModule;
