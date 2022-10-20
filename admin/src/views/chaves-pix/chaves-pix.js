	'use strict';

import config from './chaves-pix.config';
import directiveAdd from './directives/add/add';

const ngModule = angular.module('views.chaves-pix', [
	directiveAdd.name
])
	.config(config)

	.controller('viewChavesPixController', function (
		$scope,
		collectionChavesPix,
		navbarTopLeftFactory,
		appAuthHelper,
		chavesPixAddFactory,
		contasService
	) {

		$scope.user = null;
		$scope.collectionChavesPix = collectionChavesPix;

		navbarTopLeftFactory.extend([{
			label: 'Atualizar',
			onClick: function () {
				contasService.updatePixKeys({
					idEmpresa: appAuthHelper.profile.user.idEmpresa
				});
			},
			icon: 'fas fa-refresh'
		},
		{
			label: 'Solicitar nova Chave',
			onClick: function () {
				chavesPixAddFactory.add(null);
			},
			icon: 'fas fa-plus'
		}]);

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionChavesPix.collection.startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionChavesPix.collection.destroySnapshot();
		});

	});


export default ngModule;
