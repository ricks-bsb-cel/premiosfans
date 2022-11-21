'use strict';

var view = 'titulosPremios';
var controller = 'viewTitulosPremiosController';

var configPath = {
	path: '/titulos-premios/',
	label: 'Títulos Premios',
	id: 'EZOMxwi5deebckGjz7Vy'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

const config = function (
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
