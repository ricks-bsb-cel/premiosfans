
const ngModule = angular.module('directives.navbar-search', [])

	.factory('navbarSearchFactory',
		function (
		) {

			var searchValue = null;
			var enabled = false;
			var callback = null;

			var onSearch = function (cb) {
				callback = cb;
			}

			var isEnabled = function () {
				return enabled;
			}

			var setEnabled = function (e) {
				enabled = e;
			}

			var setSearchValue = function (v) {
				searchValue = v;
				if (typeof callback == 'function') {
					callback(v);
				}
			}

			return {
				setEnabled: setEnabled,
				setSearchValue: setSearchValue,
				isEnabled: isEnabled,
				onSearch: onSearch
			};

		})

	.controller('navbarSearchController',
		function (
			$scope,
			navbarSearchFactory
		) {

			$scope.navbarSearch = navbarSearchFactory;
			$scope.search = null;

			$scope.clear = function(){
				$scope.search = null;
				navbarSearchFactory.setSearchValue(null);
			}

			$scope.$watch('search', nv => {
				navbarSearchFactory.setSearchValue(nv || null);
			})

		}
	)

	.directive('navbarSearch', function () {
		return {
			restrict: 'A',
			templateUrl: 'navbar-search/navbar-search.html',
			controller: 'navbarSearchController'
		};
	});

export default ngModule;
