'use strict';

import config from './contas.config';

const ngModule = angular.module('views.contas', [
])
	.config(config)

	.controller('viewContasController', function (
		$scope,
		collectionContas,
		contasService,
		appAuthHelper,
		navbarTopLeftFactory
	) {

		$scope.user = null;
		$scope.collectionContas = collectionContas;

		navbarTopLeftFactory.extend([{
		label: 'Atualizar',
			onClick: function () {
				contasService.updateAccounts({
					idEmpresa: appAuthHelper.profile.user.idEmpresa
				});
			},
			icon: 'fas fa-refresh'
		}]);

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionContas.collection.startSnapshot();
			})

		$scope.updateBalance = function (idEmpresa, idConta) {
			contasService.updateBalance({
				idEmpresa: idEmpresa,
				idConta: idConta
			});
		}

		$scope.$on('$destroy', function () {
			$scope.collectionContas.collection.destroySnapshot();
		});

	});


export default ngModule;
