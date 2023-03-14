'use strict';

let ngModule = angular.module('directives.influencers-campanha-list', [])

    .controller('influencersCampanhaListController',
        function (
            $scope
        ) {

        

        })

    .directive('influencersCampanhaList', function () {
        return {
            restrict: 'E',
            templateUrl: 'influencers-campanha-list/influencers-campanha-list.html',
            controller: 'influencersCampanhaListController',
            scope: {
                influencers: "="
            }
        };
    });

export default ngModule;
