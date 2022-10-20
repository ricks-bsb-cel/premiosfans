'use strict';

import config from './zoe-accounts.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.zoe-accounts', [
	directiveEdit.name
])
	.config(config)

	.controller('viewZoeAccountsController', function (
		$scope,
		collectionZoeAccounts,
		zoeAccountsEditFactory,
		toastrFactory,
		appAuthHelper
	) {

		$scope.collectionZoeAccounts = collectionZoeAccounts;

		$scope.user = null;

		$scope.edit = function (e) {
			zoeAccountsEditFactory.edit(e);
		}

		$scope.filter = {
			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				} else {
					attrFilter.orderBy = "nome";
					attrFilter.limit = 20;
					toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
				}

				$scope.collectionZoeAccounts.collection.startSnapshot(attrFilter);

			}
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionClientes.collection.destroySnapshot();
		});

	});


export default ngModule;
