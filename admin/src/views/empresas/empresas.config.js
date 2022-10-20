
'use strict';

var config;

var view = 'empresas';
var controller = 'viewEmpresasController';
var requireLogin = true;

var configPath = {
	path: '/empresas/',
	label: 'Empresas',
	id: 'SYQrefgN2tjUN8q809PR'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {

	/*
	if (!window.location.pathname.startsWith('/adm/home')) {
		return;
	}
	*/
	
	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
