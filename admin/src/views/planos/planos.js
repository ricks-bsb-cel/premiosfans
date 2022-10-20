'use strict';

import config from './planos.config';
import directiveEdit from './directives/edit/edit';
import generateFakeData from './directives/generateFakeData/generateFakeData';

const ngModule = angular.module('views.planos', [
	directiveEdit.name,
	generateFakeData.name
])
	.config(config)

	.controller('viewPlanosController', function (
		$scope,
		navbarTopLeftFactory,
		collectionPlanos,
		generateFakeDataFactory,
		appAuthHelper,
		planosEditFactory
	) {

		$scope.user;
		$scope.collectionPlanos = collectionPlanos;

		$scope.edit = function (e) {
			planosEditFactory.edit(e);
		}

		const showMenu = _ => {

			let menu = [
				{
					label: 'Novo Plano',
					onClick: function () { $scope.edit(null); },
					icon: 'fas fa-plus'
				}
			];

			if ($scope.user.superUser) {
				menu.push({
					label: 'Remove dados de Teste',
					onClick: function () {
						console.info('remove fake data');
					},
					icon: 'fas fa-users-slash'
				});
			}

			navbarTopLeftFactory.extend(menu);

		}

		$scope.generateFakeData = plano => {
			generateFakeDataFactory.show(plano);
		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionPlanos.collection.startSnapshot();
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionPlanos.collection.destroySnapshot();
		});

	});


export default ngModule;
