'use strict';

var config;

var view = 'pagamentos';
var controller = 'viewFolhaPagamentosController';
var requireLogin = true;

var configPath = {
	path: '/folha/pagamentos/',
	label: 'Pagamentos',
	icon: 'fas fa-code',
	id: '0huRt0chlzF7OWIQVsm9'
};

var route = {
	templateUrl: 'folha/pagamentos/pagamentos.html',
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {
	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
