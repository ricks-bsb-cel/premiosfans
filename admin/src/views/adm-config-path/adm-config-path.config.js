'use strict';

var view = 'adm-config-path';
var controller = 'viewAdmConfigPathController';

var configPath = {
	path: '/adm-config-path/',
	label: 'Angular Route Configuration',
	id: 'S7VKnhSVnQxA6GVmSLkm'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

var config = function (
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

	$routeProvider.when(pathObj.path, route);

};

export default config;
