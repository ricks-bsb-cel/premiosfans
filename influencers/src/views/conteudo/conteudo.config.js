'use strict';

var config;

var view = 'conteudo';
var controller = 'viewConteudoController';

var configPath = {
	path: '/conteudo/:sigla',
	label: 'conteudo',
	icon: 'fas fa-clipboard'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {

	var pathObj = pathProvider.addPath(view, configPath);
	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
