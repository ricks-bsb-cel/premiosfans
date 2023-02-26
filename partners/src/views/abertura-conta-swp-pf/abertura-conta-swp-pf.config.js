'use strict';

var view = 'abertura-conta-swp-pf';
var controller = 'viewAberturaContaSwiperPFController';

var configPath = {
	path: '/abertura-conta-swp-pf',
	label: 'abertura-conta-swp-pf'
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
