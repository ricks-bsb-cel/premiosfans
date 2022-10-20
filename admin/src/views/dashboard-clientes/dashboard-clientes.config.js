'use strict';

var config;

var view = 'dashboard-clientes';
var controller = 'viewDashboardClientesController';
var requireLogin = true;

var configPath = {
	path: '/dashboard-clientes/',
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

	$routeProvider.when(path, route);

};

export default config;
