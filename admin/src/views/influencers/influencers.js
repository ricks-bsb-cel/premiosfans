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
		influencersEditFactory,
		navbarTopLeftFactory
	) {

		$scope.collectionEmpresas = collectionEmpresas;
		$scope.isSuperUser = false;

		$scope.edit = function (e) {
			influencersEditFactory.edit(e);
		}

		const loadData = termo => {
			var attrFilter = {};

			if (termo) {
				attrFilter.filter = `keywords array-contains ${termo}`;
			}

			$scope.collectionEmpresas.collection.startSnapshot(attrFilter);
		}

		$scope.filter = {
			run: function (termo) {
				loadData(termo);
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
				loadData();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionEmpresas.collection.destroySnapshot();
		});

	});


export default ngModule;
