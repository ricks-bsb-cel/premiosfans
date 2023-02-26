'use strict';

var view = 'account-open';
var controller = 'viewAccountOpenController';

var configPath = {
	path: '/account-open/:type/:id',
	label: 'account-open'
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
