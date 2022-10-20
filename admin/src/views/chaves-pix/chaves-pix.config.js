'use strict';

var config;

var view = 'chaves-pix';
var controller = 'viewChavesPixController';
var requireLogin = true;

var configPath = {
	path: '/chaves-pix/',
	label: 'chaves-pix',
	id: '0nMvipIXwYlWFxKU7X5A'
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

	/*
	if (!window.location.pathname.startsWith('/adm/home')) {
		return;
	}
	*/

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
