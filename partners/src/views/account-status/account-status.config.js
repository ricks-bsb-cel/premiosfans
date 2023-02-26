'use strict';

var view = 'account-status';
var controller = 'viewAccountStatusController';

var configPath = {
	path: '/account-status',
	label: 'account-status'
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
