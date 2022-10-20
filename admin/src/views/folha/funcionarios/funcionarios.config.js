'use strict';

var config;

var view = 'funcionarios';
var controller = 'viewFolhaFuncionariosController';
var requireLogin = true;

var configPath = {
	path: '/folha/funcionarios/',
	label: 'Cadastro de Funcionários',
	icon: 'fas fa-code',
	id: "cwH8I8EtinNqZxWM5Yu3"
};

var route = {
	templateUrl: 'folha/funcionarios/funcionarios.html',
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
