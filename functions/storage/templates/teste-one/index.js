window.odometerOptions = {
    format: '(,ddd).ddd',
    numberLength: 6,
    duration: 500,
};

angular.module('app', [
])
    .factory('global', function (
    ) {
        const guid = function () {
            var d = new Date().getTime();
            var d2 = (performance && performance.now && (performance.now() * 1000)) || 0;
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16;
                if (d > 0) {
                    r = (d + r) % 16 | 0;
                    d = Math.floor(d / 16);
                } else {
                    r = (d2 + r) % 16 | 0;
                    d2 = Math.floor(d2 / 16);
                }
                return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
            });
        };

        return {
            guid: guid
        }
    })

    .factory('generateTitulosFactory', function (
        global,
        $timeout
    ) {
        let qtdTitulos = 1,
            titulos = [],
            visible = false,
            delegate = {};

        const setTitulos = _ => {
            visible = false;

            if (titulos.length > qtdTitulos) titulos.length = qtdTitulos;

            while (titulos.length < qtdTitulos) {
                titulos.push({
                    codigo: 0,
                    id: global.guid()
                })
            }
        }

        const isVisible = _ => {
            return visible;
        }

        const getQtdTitulos = _ => {
            return qtdTitulos;
        }

        const setQtdTitulos = qtd => {
            if (qtdTitulos === qtd) return;
            qtdTitulos = qtd;
            setTitulos();

            delegate.hideFormCliente();
        }

        const getTitulos = _ => {
            return titulos;
        }

        const generateNumbers = _ => {

            $timeout(_ => {
                visible = true;

                $timeout(_ => {

                    titulos.forEach(t => {
                        // https://www.jqueryscript.net/animation/animating-roll-number.html
                        $(`.id-${t.id}`).rollNumber({
                            number: 1 + Math.floor(Math.random() * 999999),
                            speed: 2000,
                            interval: 200,
                            rooms: 6,
                            space: 20,
                            fontStyle: {
                                'font-size': 30,
                                'color': "green",
                                'font-family': "monospace",
                                'font-weight': "bold"
                            }
                        })
                    })

                    delegate.showFormCliente();

                })
            })
        }

        return {
            qtdTitulos: qtdTitulos,
            getQtdTitulos: getQtdTitulos,
            setQtdTitulos: setQtdTitulos,
            getTitulos: getTitulos,
            generateNumbers: generateNumbers,
            isVisible: isVisible,
            delegate: delegate
        }
    })

    .directive('generateTitulos', function (
        generateTitulosFactory
    ) {
        return {
            restrict: 'E',
            replace: true,
            controller: function ($scope) {
                $scope.generate = generateTitulosFactory;
            },
            template: `
                <article class="pt-20 pb-20 mb-0 mt-5" ng-show="generate.isVisible()">
                    <hgroup class="mt-10">
                        <h2>Seus números</h2>
                        <h3>
                            Veja os números que escolhemos para você.
                        </h3>
                    </hgroup>
                    <div class="row mb-20">
                        <div ng-repeat="t in generate.getTitulos()" class="col-6 col-xs-6 col-sm-4 col-md-4 col-lg-4 col-xl-3 mb-20 mt-10">
                            <div class="titulo titulo-number id-{{t.id}}"></div>
                        </div>
                    </div>
                </article>`
        };
    })

    .directive('formCliente', function (generateTitulosFactory) {
        return {
            restrict: 'E',
            controller: function ($scope) {
                $scope.initDelegates = _ => {
                    generateTitulosFactory.delegate.showFormCliente = _ => {
                        $("#form-cliente").show();
                    }

                    generateTitulosFactory.delegate.hideFormCliente = _ => {
                        $("#form-cliente").hide();
                    }
                }
            },
            templateUrl: `/templates/teste-one/form-cliente.html?v=${version}`,
            link: function (scope, element) {
                scope.initDelegates();
            }
        };

    })

    .controller('mainController', function (
        $scope,
        generateTitulosFactory
    ) {
        $scope.selected = null;
        $scope.vlCompra = null;
        $scope.swiperPremios = null;

        $scope.selectQtd = (id, vlTotal, qtd) => {
            $scope.selected = id;
            $scope.vlCompra = vlTotal;

            $("#vl-total").show();

            generateTitulosFactory.setQtdTitulos(qtd);
        }

        $scope.openSell = _ => {
            if (!$scope.vlCompra) {
                Swal.fire('Ooops!', 'Selecione uma quantidade de títulos desejada!', 'info');
                return;
            }

            generateTitulosFactory.generateNumbers();
        }


    });
