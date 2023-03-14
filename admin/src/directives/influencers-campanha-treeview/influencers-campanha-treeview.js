'use strict';

let ngModule = angular.module('directives.influencers-campanha-treeview', [])

    .controller('influencersCampanhaTreeviewController',
        function (
            $scope
        ) {

            $scope.treeOptions = {
				nodeChildren: "children",
				dirSelectable: true
			};

            $scope.treeViewData = [
				{
					nodeType: "root",
					isRoot: true,
					nome: "Influencers",
					children: []
				}
			]

        })

    .directive('influencersCampanhaTreeview', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha-treeview/influencers-campanha-treeview.html',
            controller: 'influencersCampanhaTreeviewController',
            scope: {
                influencers: "="
            }
        };
    });

export default ngModule;
