'use strict';

var view = 'abertura-conta-swp-pj';
var controller = 'viewAberturaContaSwiperPJController';

var configPath = {
	path: '/abertura-conta-swp-pj',
	label: 'abertura-conta-swp-pj'
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
