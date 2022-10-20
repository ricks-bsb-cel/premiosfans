'use strict';

var config;

var view = 'dashboard-clientes-cobrancas';
var controller = 'viewDashboardClientesCobrancasController';
var requireLogin = true;

var configPath = {
	path: '/dashboard-clientes-cobrancas/',
	label: 'Dashboard Clientes',
	icon: 'fas fa-clipboard'
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

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path + ':idEmpresa/:idContrato', route);

};

export default config;
