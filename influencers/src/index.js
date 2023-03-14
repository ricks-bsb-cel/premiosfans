'use strict';

import vendor from '../vendor/vendor';
import providers from './providers/providers';
import config from './config/config';
import formly from './formly/formly';
import templates from './app-templates';
import factories from './factories/factories';
import services from './services/services';
import directives from './directives/directives';
import views from './views/views';

import './app-sass';

window._config = window._config || {};

angular.module('clienteLoginApp', [
    vendor.name,
    providers.name,
    config.name,
    formly.name,
    templates.name,
    factories.name,
    services.name,
    directives.name,
    views.name
]);