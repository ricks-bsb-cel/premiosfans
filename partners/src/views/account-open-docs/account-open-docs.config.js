'use strict';

var view = 'account-open-docs';
var controller = 'viewAccountOpenDocsController';

var configPath = {
	path: '/account-open-docs/:type/:id',
	label: 'account-open-docs'
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
	var pathObj = pathProvider.addPath(view, configPath);
	var path = pathObj.path;

	$routeProvider.when(path, route);
};

export default config;
