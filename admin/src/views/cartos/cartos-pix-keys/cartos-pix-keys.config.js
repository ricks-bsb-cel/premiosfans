'use strict';

var view = 'cartos-pix-keys';
var controller = 'viewCartosPixKeysController';

var configPath = {
	path: '/cartos-pix-keys',
	label: 'Chave Pix Cartos',
	id: 'wGQB7MwNIr3g0Xz6aSVN'
};

var route = {
	templateUrl: 'cartos/' + view + '/' + view + '.html',
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
