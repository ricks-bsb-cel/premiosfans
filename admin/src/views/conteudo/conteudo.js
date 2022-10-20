'use strict';

import config from './conteudo.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.conteudo', [
	directiveEdit.name
])
	.config(config)

	.controller('viewConteudoController', function (
		$scope,
		navbarTopLeftFactory,
		collectionConteudo,
		appAuthHelper,
		conteudoEditFactory
	) {

		$scope.user;
		$scope.collectionConteudo = collectionConteudo;

		$scope.edit = function (e) {
			conteudoEditFactory.edit(e);
		}

		const showMenu = _ => {

			let menu = [
				{
					label: 'Novo Conteúdo',
					onClick: function () { $scope.edit(null); },
					icon: 'fas fa-plus'
				}
			];

			navbarTopLeftFactory.extend(menu);

		}

		appAuthHelper.ready()
			.then(_ => {
				$scope.user = appAuthHelper.profile.user;
				$scope.collectionConteudo.collection.startSnapshot();
				showMenu();
			})

		$scope.$on('$destroy', function () {
			$scope.collectionConteudo.collection.destroySnapshot();
		});

	});


export default ngModule;
