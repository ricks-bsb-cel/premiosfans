'use strict';

var config;

var view = 'cobrancas';
var controller = 'viewCobrancasController';
var requireLogin = true;

var configPath = {
	path: '/cobrancas/',
	label: 'Cobranças',
	id: 'rlbUboVFont6Y6Z62UMU'
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

	$routeProvider.when(path + ':idCliente?/:idContrato?', route);

};

export default config;
