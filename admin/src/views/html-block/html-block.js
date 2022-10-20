'use strict';

import config from './html-block.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.html-block', [
	directiveEdit.name
])
	.config(config)

	.controller('viewHtmlBlockController', function (
		$scope,
		navbarTopLeftFactory,
		collectionHtmlBlock,
		appAuthHelper,
		htmlBlockEditFactory
	) {

		$scope.user;
		$scope.collectionHtmlBlock = collectionHtmlBlock;

		$scope.edit = function (e) {
			htmlBlockEditFactory.edit(e);
		}

		const showMenu = _ => {

			let menu = [
				{
					label: 'Novo HTML',
					onClick: function () { $scope.edit(null); },
					icon: 'fas fa-plus'
				}
			];

			navbarTopLeftFactory.extend(menu);

		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionHtmlBlock.collection.startSnapshot();
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionHtmlBlock.collection.destroySnapshot();
		});

	});


export default ngModule;
