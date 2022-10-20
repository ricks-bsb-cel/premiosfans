'use strict';

var config;

var view = 'global-config';
var controller = 'viewGlobalConfigController';
var requireLogin = true;

var configPath = {
	path: '/global-config/',
	label: 'Global Config',
	id: '03CWmJht4JNKPsHWvlsH'
};

var route = {
	templateUrl: `${view}/${view}.html`,
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {
	var pathObj = pathProvider.addPath(view, configPath);
	var path = pathObj.path;

	$routeProvider.when(path, route);
};

export default config;
