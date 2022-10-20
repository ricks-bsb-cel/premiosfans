
'use strict';

var config;

var view = 'messagesReceived';
var controller = 'viewMessagesReceivedController';
var requireLogin = true;

var configPath = {
	path: '/messages-received/',
	label: 'Messages Received',
	icon: 'fas fa-code'
};

var route = {
	templateUrl: view + '/' + view + '.html',
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
