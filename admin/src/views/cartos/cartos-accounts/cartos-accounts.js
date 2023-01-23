'use strict';

import config from './cartos-accounts.config';

const ngModule = angular.module('views.cartos-accounts', [
])
	.config(config)

	.controller('viewCartosAccountsController', function (
		$scope,
		appAuthHelper,
		collectionCartosAccounts,
		toastrFactory,
		premiosFansService
	) {

		$scope.collectionCartosAccounts = collectionCartosAccounts;

		const startSnapshot = termo => {
			var attrFilter = { filter: [] };

			if (termo) {
				attrFilter.filter.push({ field: "keywords", operator: "array-contains", value: termo });
			} else {
				attrFilter.limit = 60;
				toastrFactory.info('Apenas os primeiros ' + attrFilter.limit + ' registros serão apresentados... Informe um termo de pesquisa para buscar dados mais específicos.');
			}

			$scope.collectionCartosAccounts.collection.startSnapshot(attrFilter);
		}

		$scope.filter = {
			run: function (termo) {
				startSnapshot(termo);
			}
		}

		$scope.refresh = account => {
			premiosFansService.refreshCartosPixKeys({
				data: {
					cpf: account.cpf,
					accountId: account.accountId
				}
			})
		}

		appAuthHelper.ready()
			.then(_ => {
				// startSnapshot();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionCartosAccounts.collection.destroySnapshot();
		});

	});


export default ngModule;
