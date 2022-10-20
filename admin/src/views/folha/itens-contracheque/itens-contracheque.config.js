'use strict';

var config;

var view = 'itens-contracheque';
var controller = 'viewFolhaItensContraChequeController';
var requireLogin = true;

var configPath = {
	path: '/folha/itens-contracheque/',
	label: 'Ítens do Contra Cheque',
	id: "rdKL3ejAgw0jyOTwO5vh"
};

var route = {
	templateUrl: `folha/${view}/${view}.html`,
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
