import viewCrudDemo from './crud/crud';
import viewBlankDemo from './blank/blank';

let ngModule = angular.module('view._templates_', [
	viewCrudDemo.name,
	viewBlankDemo.name
]);

export default ngModule;
