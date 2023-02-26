'use strict';

import './sass/app.scss';

import 'swiper/css';
import 'swiper/css/navigation';
import 'swiper/css/pagination';

let importAll = function(r){
	r.keys().forEach(key => {
		if(!/\.resource\.scss/.test(key)){
			r(key);
		}
	});
};

importAll;

importAll(require.context('./directives/', true, /\.scss/));
importAll(require.context('./factories/', true, /\.scss/));
importAll(require.context('./formly/', true, /\.scss$/));
importAll(require.context('./views/', true, /\.scss$/));
