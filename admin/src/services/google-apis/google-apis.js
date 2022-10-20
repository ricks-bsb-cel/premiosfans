
import automplete from './autocomplete';
import details from './details';

const ngModule = angular.module('services.google-apis', [
	automplete.name,
	details.name
]);

export default ngModule;
