'use strict';

var config;

var view = 'vault';
var controller = 'viewVaultController';
var requireLogin = true;

var configPath = {
	path: '/vault/',
	label: 'Vault',
	icon: 'fas fa-code'
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
