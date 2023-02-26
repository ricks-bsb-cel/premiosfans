'use strict';

var view = 'account-choose-type';
var controller = 'viewAccountChooseTypeController';

var configPath = {
	path: '/account-choose-type/',
	label: 'account-choose-type'
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
