'use strict';

var view = 'adm-config-profile-edit';
var controller = 'viewAdmConfigProfileEditController';

var configPath = {
	path: '/adm-config-profile-edit/',
	label: 'Edição de Perfil de Acesso',
	icon: 'fas fa-code'
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

	$routeProvider.when(pathObj.path + ':id', route);

};

export default config;
