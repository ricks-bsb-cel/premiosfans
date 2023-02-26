
const ngModule = angular.module('directives.close-canvas-on-click', [])

	.directive('closeCanvasOnClick', function (
	) {
		return {
			restrict: 'A',
			link: function (scope, element) {
				const canvas = element.attr('close-canvas-on-click');
				if (canvas) {
					element.on('click', _ => {
						const e = document.getElementById(canvas);
						if (e) {
							bootstrap.Offcanvas.getInstance(e).hide();
						}
					});
				}
			}
		};
	});

export default ngModule;
