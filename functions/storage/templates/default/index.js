angular.module('app', [
])
    .controller('mainController', function (
        $scope,
        $timeout
    ) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal) => {
            $scope.selected = id;
            $scope.vlCompra = vlTotal;
        }

        $scope.openSell = _ => {
            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
            }
        }

        const initSwiperPremios = _ => {
            $scope.swiperPremios = new Swiper(".swiper.swiper-premios", {
                slidesPerView: 1,
                spaceBetween: 5,
                pagination: {
                    el: ".swiper-pagination",
                    clickable: true,
                },
                breakpoints: {
                    640: {
                        slidesPerView: 2,
                        spaceBetween: 20,
                    },
                    768: {
                        slidesPerView: 4,
                        spaceBetween: 40,
                    },
                    1024: {
                        slidesPerView: 5,
                        spaceBetween: 50,
                    },
                },
            });
        }

        $timeout(_=>{
            initSwiperPremios();
        })


    });
