'use strict';

var view = 'account-open-user';
var controller = 'viewAccountOpenUserController';

var configPath = {
	path: '/account-open-user/:type/:id',
	label: 'account-open-user'
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
