'use strict';

import config from './global-config.config';

const ngModule = angular.module('views.global-config', [
])
	.config(config)

	.controller('viewGlobalConfigController', function (
		$scope,
		appAuthHelper,
		appDatabase,
		appDatabaseHelper,
		navbarTopLeftFactory,
		toastrFactory,
		appErrors
	) {

		$scope.readyGlobal = false;
		$scope.readyEmpresa = false;
		$scope.empresaAtual = null;

		$scope.jsonDataGlobal = {};
		$scope.jsonDataEmpresa = {};

		const db = appDatabase.database;

		var detachSnapshotGlobal = null;
		var detachSnapshotEmpresa = null;

		const loadGlobalConfig = _ => {

			var refGlobal = appDatabase.ref(db, 'globalConfig');
			var refEmpresa = appDatabase.ref(db, 'configEmpresa/' + $scope.empresaAtual.id);

			detachSnapshotGlobal = appDatabase.onValue(refGlobal, data => {
				if (data.exists()) {
					$scope.jsonDataGlobal = data.val();
					$scope.readyGlobal = true;
					showMenu();
				}
			}, e => {
				appErrors.showError(e);
			});

			detachSnapshotEmpresa = appDatabase.onValue(refEmpresa, data => {
				$scope.jsonDataEmpresa = data.val() || {};
				$scope.readyEmpresa = true;
				showMenu();
			}, e => {
				appErrors.showError(e);
			});
		}

		const save = _ => {
			appDatabaseHelper.set('globalConfig', $scope.jsonDataGlobal).then(_ => {
				toastrFactory.success('Configuração global salva com sucesso...');
			})
			appDatabaseHelper.set('configEmpresa/' + $scope.empresaAtual.id, $scope.jsonDataEmpresa).then(_ => {
				toastrFactory.success(`Configuração da empresa ${$scope.empresaAtual.nome} salva com sucesso...`);
			})
		}

		const showMenu = _ => {
			navbarTopLeftFactory.extend([
				{
					id: 'save',
					label: 'Salvar',
					onClick: save,
					class: 'btn btn-block btn-primary',
					icon: 'far fa-save'
				}
			]);
		}

		$scope.$on('$viewContentLoaded', function () {
			appAuthHelper.ready().then(_ => {
				$scope.empresaAtual = appAuthHelper.profile.user.empresaAtual;
				loadGlobalConfig();
			})
		});

		$scope.$on('$destroy', function () {
			detachSnapshotGlobal();
			detachSnapshotEmpresa();
		});

	});

export default ngModule;
