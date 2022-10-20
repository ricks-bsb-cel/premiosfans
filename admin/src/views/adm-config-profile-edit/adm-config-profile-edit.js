'use strict';

import config from './adm-config-profile-edit.config';
import editSecao from './directives/edit-section/edit-section';

let ngModule = angular.module('views.admConfigProfileEdit', [
	editSecao.name
])
	.config(config)

	.controller('viewAdmConfigProfileEditController', function (
		$scope,
		$routeParams,
		$location,
		appAuthHelper,
		navbarTopLeftFactory,
		collectionAdmConfigPath,
		collectionAdmConfigProfiles,
		admConfigProfilesEditSectionFactory,
		alertFactory
	) {

		$scope.id = $routeParams.id;

		$scope.user = null;

		$scope.fields = [
			{
				key: 'titulo',
				templateOptions: {
					label: 'Descrição',
					type: 'text',
					required: true,
					minlength: 3,
					maxlength: 64
				},
				type: 'input',
				className: 'col-xs-12 col-sm-12 col-md-8 col-lg-8 col-xl-9'
			},
			{
				key: 'id',
				templateOptions: {
					label: 'ID',
					required: true,
					type: 'text'
				},
				type: 'input',
				ngModelElAttrs: { disabled: 'true' },
				className: 'id-perfil col-xs-12 col-sm-12 col-md-4 col-lg-4 col-xl-3'
			}
		];

		const save = function () {
			collectionAdmConfigProfiles.save($scope.profile).then(_ => {
				$location.path('/adm-config-profiles');
			})
		}

		navbarTopLeftFactory.extend([
			{
				id: 'back',
				route: '/adm-config-profiles/'
			},
			{
				id: 'save',
				label: 'Salvar',
				onClick: save,
				class: 'btn btn-block btn-primary',
				icon: 'far fa-save'
			},
			{
				label: 'Nova Seção',
				onClick: function () {
					$scope.edit(null);
				},
				icon: 'fas fa-plus'
			}
		]);

		$scope.sortableOptions = {
			placeholder: 'draggable', // no ng-repeat
			connectWith: '.sortable', // Junto do sortableOptions
			update: function (e, ui) {
				setOptions();
			}
		};

		$scope.notUsed = [];
		$scope.profile = { groups: [] };

		$scope.upGroup = function (currentPos) {
			const previousPos = currentPos - 1;
			const temp = $scope.profile.groups[previousPos];

			$scope.profile.groups[previousPos] = $scope.profile.groups[currentPos];
			$scope.profile.groups[currentPos] = temp;
		}

		$scope.downGroup = function (currentPos) {
			const nextPos = currentPos + 1;
			const temp = $scope.profile.groups[nextPos];

			$scope.profile.groups[nextPos] = $scope.profile.groups[currentPos];
			$scope.profile.groups[currentPos] = temp;
		}

		$scope.deleteGroup = function (id) {
			alertFactory.yesno('Tem certeza que deseja remover o Grupo?').then(() => {
				// Antes de remover, manda todos os ítens de volta para os não utilizados
				const i = $scope.profile.groups.findIndex(f => { return f.id === id; });
				if (i >= 0) {
					$scope.notUsed = $scope.notUsed.concat($scope.profile.groups[i].options);
					$scope.profile.groups = $scope.profile.groups.filter(f => { return f.id !== id; });
				}
			})
		}

		$scope.edit = function (secao) {
			admConfigProfilesEditSectionFactory.edit(secao).then(secao => {

				var i = $scope.profile.groups.findIndex(f => { return f.id === secao.id; });

				if (i < 0) {
					$scope.profile.groups.push(secao);
				} else {
					$scope.profile.groups[i].titulo = secao.titulo;
					$scope.profile.groups[i].icon = secao.icon;
				}

			});
		}

		const setOptions = function () {
			$scope.profile.groups.forEach(g => {
				g.options.forEach(o => {
					o.create = typeof o.create === 'boolean' ? o.create : true;
					o.update = typeof o.update === 'boolean' ? o.update : true;
					o.delete = typeof o.delete === 'boolean' ? o.delete : false;
				})
			})
		}

		appAuthHelper.ready()
			.then(_ => {

				collectionAdmConfigPath.collection.onLoadFinish(collectionAdmConfigPathData => {

					$scope.notUsed = collectionAdmConfigPathData.filter(f => { return f.directRoute; });

					if ($scope.id === 'new') {
						$scope.ready = true;
						$scope.edit();
					} else {

						collectionAdmConfigProfiles.getById($scope.id)
							.then(profile => {
								$scope.profile = profile;

								$scope.profile.groups.forEach(g => {
									g.options.forEach(o => {
										var i = $scope.notUsed.findIndex(f => { return f.id === o.id; });
										if (i >= 0) {
											o.icon = $scope.notUsed[i].icon;
											o.href = $scope.notUsed[i].href;
											o.label = $scope.notUsed[i].label;
											$scope.notUsed[i].delete = true;
										}
									})
								})

								$scope.notUsed = $scope.notUsed
									.filter(f => { return !f.delete; })
									.sort(function (a, b) {
										return a.label > b.label ? 1 : -1;
									});

								$scope.ready = true;
							})
					}

				})

			});

		$scope.$on('$destroy', function () {
			// collectionAdmConfigPath.collection.destroy();
		});

	})

export default ngModule;





/*
firebaseService.registerListenersAuthStateChanged(user => {
	if (user) {
		$scope.user = user;

		collectionAdmConfigPath.collection.get({
			directRoute: true
		})

			.then(result => {
				$scope.notUsed = result;

				if ($scope.id === 'new') {
					$scope.ready = true;
					$scope.edit();
				} else {
					collectionAdmConfigProfiles.collection.getDoc($scope.id).then(profile => {
						$scope.profile = profile;

						$scope.profile.groups.forEach(g => {
							g.options.forEach(o => {
								var i = $scope.notUsed.findIndex(f => { return f.id === o.id; });
								if (i >= 0) {
									o.icon = $scope.notUsed[i].icon;
									o.href = $scope.notUsed[i].href;
									$scope.notUsed[i].delete = true;
								}
							})
						})

						$scope.notUsed = $scope.notUsed
							.filter(f => { return !f.delete; })
							.sort(function (a, b) { return a.label > b.label ? 1 : -1; });

						$scope.ready = true;
					})
				}
			});

	}
})

firebaseService.init();
*/