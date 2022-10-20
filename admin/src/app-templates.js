
const ngModule = angular.module('adminAppTemplates', []);

let importAll = function(r){
	r.keys().forEach(key => {
		r(key);
	});
};

importAll(require.context('./directives/', true, /\.html$/));
importAll(require.context('./factories/', true, /\.html$/));
importAll(require.context('./views/', true, /\.html$/));
importAll(require.context('./formly/', true, /\.html$/));

export default ngModule;
