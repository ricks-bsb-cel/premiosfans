angular.module('app', [
])
    .controller('mainController', function ($scope) {
        $scope.selected = null;
        $scope.vlCompra = null;

        $scope.selectQtd = (id, vlTotal) => {
            $scope.selected = id;
            $scope.vlCompra = vlTotal;
        }

        $scope.openSell = _ => {
            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
            }
        }
    });
