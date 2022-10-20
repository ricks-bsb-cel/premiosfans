const ngModule = angular.module('directives.linkClick', [])

    .directive('a', function () {
        return {
            restrict: 'E',
            link: (scope, elem, attrs) => {
                if (
                    attrs.ngClick ||
                    (attrs.href && attrs.href.substring(0, 4) === '#tab') ||
                    (attrs.href && !attrs.href.includes('#!/'))
                ) {
                    elem.on('click', (e) => {
                        e.preventDefault(); // prevent link click for above criteria
                    });
                }
            }
        };
    });

export default ngModule;
