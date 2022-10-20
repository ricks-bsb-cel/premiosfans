import baseDatabase from './firebase.base.database';

let ngModule = angular.module('databases', [
	baseDatabase.name
]);

export default ngModule;