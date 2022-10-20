
'use strict';

var config;

var view = 'global-whatsapp';
var controller = 'viewGlobalWhatsappController';
var requireLogin = true;

var configPath = {
	path: '/global-whatsapp/',
	label: 'Global Whatsapp',
	icon: 'fas fa-code'
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
