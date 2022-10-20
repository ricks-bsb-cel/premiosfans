
const ngModule = angular.module('directives.navigation', [])

	.controller(
		'navigationController',
		function (
			$scope,
			firebaseService,
			collectionAdmConfigPath
		) {

			$scope.user = null;
			$scope.collectionAdmConfigPath = collectionAdmConfigPath;
			$scope.options = [];

			firebaseService.getProfile(userProfile => {
				$scope.user = userProfile.user;
				$scope.collectionAdmConfigPath.collection.getSnapshot({});
			})


			/*
			firebaseService.registerListenersAuthStateChanged(function (user) {
				if (user) {
					$scope.user = user;
					$scope.collectionAdmConfigPath.collection.getSnapshot({});
				}
			})
			*/

			/*
			var options = path.getAllPaths();

			$scope.itens = [];
			$scope.groups = [];

			$scope.menuButtonPlugins = function () {
				var result = [];

				return result;
			}

			var addToGroup = function (groupName, option) {
				// Verifica se o grupo já existe
				var pos = $scope.groups.findIndex(function (f) { return f.name == groupName; });
				if (pos >= 0) {
					$scope.groups[pos].options.push(option);
				} else {
					$scope.groups.push({ name: groupName, options: [] });
					addToGroup(groupName, option);
				}
			}

			firebaseService.registerListenersAuthStateChanged(function (user, adm) {

				if (!user || $scope.itens.length > 0) { return; }

				// Adiciona as Views registradas
				Object.keys(options).forEach(function (k) {

					var option = angular.merge(options[k], { id: k });

					if (
						option.menuHeader &&
						option.menuName.includes($scope.name) &&
						(!option.isSuperAdm || (option.isSuperAdm && adm.isAdm))
					) {
						addToGroup(option.menuHeader, option);
					}

				})

			})

			firebaseService.init();
			*/

		}
	)

	.directive('navigation', function () {
		return {
			restrict: 'E',
			scope: {
				name: '@'
			},
			controller: 'navigationController',
			templateUrl: 'navigation/navigation.html'
		};
	});

export default ngModule;
