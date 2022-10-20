
'use strict';

var config;

var view = 'clientes';
var controller = 'viewClientesController';
var requireLogin = true;

var configPath = {
	path: '/clientes/',
	label: 'Clientes',
	icon: 'fas fa-code',
	id: "SJitMMc2NvLkIdnCbSOF"
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
