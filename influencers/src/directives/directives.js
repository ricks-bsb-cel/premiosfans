'use strict';

import waitOverlay from './wait-overlay/wait-overlay';
import loginBlock from './login-block/login-block';
import menuSidebarHome from './menu-sidebar-home/menu-sidebar-home';
import pageHeader from './page-header/page-header';
import menuNotifications from './menu-notifications/menu-notifications';
import blockEndereco from './block-endereco/block-endereco';
import fileUpload from './file-upload/file-upload';
import accountCard from './account-card/account-card';
import accountErrorDetails from './account-error-details/account-error-details';
import footerBar from './footer-bar/footer-bar';
import closeCanvasOnClick from './close-canvas-on-click/close-canvas-on-click';
import accountDetails from './account-details/account-details';
import blockHtml from './block-html/block-html';
import blockConteudo from './block-conteudo/block-conteudo';
import phoneAuth from './phone-auth/phone-auth';

import abrirContaPJBlock from './abrir-conta-pj-block/abrir-conta-pj-block';
import abrirContaPJBlockResumo from './abrir-conta-pj-block-resumo/abrir-conta-pj-block-resumo';

const ngModule = angular.module('directives', [
    waitOverlay.name,
    loginBlock.name,
    menuSidebarHome.name,
    pageHeader.name,
    menuNotifications.name,
    blockEndereco.name,
    fileUpload.name,
    accountCard.name,
    accountErrorDetails.name,
    footerBar.name,
    closeCanvasOnClick.name,
    accountDetails.name,
    
    abrirContaPJBlock.name,
    abrirContaPJBlockResumo.name,
    
    blockHtml.name,
    blockConteudo.name,
    phoneAuth.name
]);

export default ngModule;
