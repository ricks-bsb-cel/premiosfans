'use strict';

var view = 'account-open-company';
var controller = 'viewAccountOpenCompanyController';

var configPath = {
	path: '/account-open-company/:type/:id',
	label: 'account-open-company'
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
