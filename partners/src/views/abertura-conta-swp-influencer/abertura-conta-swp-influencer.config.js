'use strict';

var view = 'abertura-conta-swp-influencer';
var controller = 'viewAberturaContaSwiperInfluencerController';

var configPath = {
	path: '/abertura-conta-swp-influencer',
	label: 'abertura-conta-swp-influencer'
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
