'use strict';

import config from './influencers.config';
import directiveEdit from './directives/edit/edit';

var ngModule;

ngModule = angular.module('views.influencers', [
	directiveEdit.name
])
	.config(config)

	.controller('viewInfluencersController', function (
		$scope,
		appAuthHelper,
		collectionEmpresas,
		empresasEditFactory,
		navbarTopLeftFactory
	) {

		$scope.collectionEmpresas = collectionEmpresas;
		$scope.isSuperUser = false;

		$scope.edit = function (e) {
			empresasEditFactory.edit(e);
		}

		$scope.filter = {
			run: function (termo) {

				var attrFilter = {};

				if (termo) {
					attrFilter.filter = `keywords array-contains ${termo}`;
				}

				$scope.collectionEmpresas.collection.startSnapshot(attrFilter);

			}
		}

		navbarTopLeftFactory.extend({
			label: 'Novo Influencer',
			onClick: function () {
				$scope.edit(null);
			},
			icon: 'fas fa-plus'
		});

		appAuthHelper.ready()
			.then(_ => {
				$scope.isSuperUser = appAuthHelper.profile.user.superUser;

				if (!$scope.isSuperUser) {
					$scope.collectionEmpresas.collection.startSnapshot({
						id:appAuthHelper.profile.user.idEmpresa
					});
				}

			})

		$scope.$on('$destroy', function () {
			$scope.collectionEmpresas.collection.destroySnapshot();
		});

	});


export default ngModule;
