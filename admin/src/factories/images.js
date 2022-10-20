'use strict';

let ngModule;

// https://cloudinary.com/documentation/javascript_image_manipulation

ngModule = angular.module('factories.images', [])

	.factory('imagesFactory',	// cloudinaryFactory

		function (
		) {

			var cloudinaryUrl = 'https://res.cloudinary.com/ycard-app/image/upload/';

			var process = function (imgUrl, type, height, width) {

				var result = null;

				if (imgUrl.includes('/res.cloudinary.com/')) {
					var file = imgUrl.substring(imgUrl.indexOf('/image') + 7);
					var parts = file.split('/').filter(function (f) {
						return f != 'upload' && f.substr(1, 1) != '_';
					})
					result = cloudinaryUrl + 'c_' + type + ',h_' + height + ',w_' + width + '/' + parts.join('/');
				}

				if (imgUrl.includes('/images.pexels.com/')) {
					var q = imgUrl.indexOf('?');
					if (q > 0) { imgUrl = imgUrl.substr(0, q); }
					result = imgUrl += '?auto=compress&cs=tinysrgb&fit=crop&h=' + height + '&w=' + width;
				}

				if (imgUrl.includes('googleusercontent.com')) {
					var q = imgUrl.lastIndexOf('=');
					if (q > 0) { imgUrl = imgUrl.substr(0, q); }
					result = imgUrl + '=w' + width + '-h' + height;
				}

				return result;

			};

			var scale = function (imgUrl, height, width) {
				return process(imgUrl, 'scale', height, width);
			};

			var crop = function (imgUrl, height, width) {
				return process(imgUrl, 'crop', height, width);
			};

			var thumb = function (imgUrl, height, width) {
				return process(imgUrl, 'thumb', height, width);
			};

			var factory = {
				scale: scale,
				crop: crop,
				thumb: thumb
			};

			return factory;
		}
	)
	.filter('crop', function (imagesFactory) {
		return function (url, width, height) {
			return imagesFactory.crop(url, width, height);
		}
	})
	.filter('scale', function (imagesFactory) {
		return function (url, width, height) {
			return imagesFactory.scale(url, width, height);
		}
	})
	.filter('thumb', function (imagesFactory) {
		return function (url, width, height) {
			return imagesFactory.thumb(url, width, height);
		}
	});

export default ngModule;
