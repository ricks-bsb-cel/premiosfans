
'use strict';

var config;

var view = 'dashboard-rh';
var controller = 'viewDashboardRHController';
var requireLogin = true;

var configPath = {
	path: '/dashboard-rh/',
	label: 'Dashboard RH',
	id: 'Te683SSgG1Cn0mTl4qKc'
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
