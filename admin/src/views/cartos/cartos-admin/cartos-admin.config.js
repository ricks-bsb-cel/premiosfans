'use strict';

var view = 'cartos-admin';
var controller = 'viewCartosAdminController';

var configPath = {
	path: '/cartos-admin',
	label: 'Administração Cartos',
	id: 'gISsCBrQYBYdOCPpk2RE'
};

var route = {
	templateUrl: 'cartos/' + view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

const config = function (
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
