'use strict';

var config;

var view = 'zoe-accounts';
var controller = 'viewZoeAccountsController';
var requireLogin = true;

var configPath = {
	path: '/zoe-accounts/',
	label: 'Zoe Accounts',
	id: "EZZZtJRrnVMT1xqZdvY4"
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
