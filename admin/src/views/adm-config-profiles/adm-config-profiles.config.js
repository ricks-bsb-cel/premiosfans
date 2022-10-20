'use strict';

var view = 'adm-config-profiles';
var controller = 'viewAdmConfigProfilesController';

var configPath = {
	path: '/adm-config-profiles/',
	label: 'Perfis de Acesso',
	id: '9X70RLnHFl4qJltZJMLF'
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

	$routeProvider.when(pathObj.path, route);

};

export default config;
