'use strict';

import config from './itens-contracheque.config';
import blockContraCheque from './directives/block-contracheque/block-contracheque';

var ngModule;

ngModule = angular.module('views.folha.itens-contracheque', [
	blockContraCheque.name
])
	.config(config)

	.controller('viewFolhaItensContraChequeController', function (
		$scope,
		navbarTopLeftFactory,
		collectionItensContraCheque,
		appAuthHelper
	) {

		$scope.collectionItensContraCheque = collectionItensContraCheque;

		navbarTopLeftFactory.extend({
			label: 'Salvar',
			onClick: function () {
				
			},
			icon: 'fas fa-save'
		});

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionItensContraCheque.collection.startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionItensContraCheque.collection.destroySnapshot();
		});

	});


export default ngModule;
