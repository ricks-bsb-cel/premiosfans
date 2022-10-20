
'use strict';

var config;

var view = 'global-dashboard';
var controller = 'viewGlobalDashboardController';
var requireLogin = true;

var configPath = {
	path: '/global-dashboard/',
	label: 'Dashboard',
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
