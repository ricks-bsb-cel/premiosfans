import loginBox from './login-box/login-box';
import navbarTopLeft from './navbar-top-left/navbar-top-left';
import navbarSearch from './navbar-search/navbar-search';
import navbarLogout from './navbar-logout/navbar-logout';
import collectionValue from './collection-value/collection-value';
import linkClick from './link-click/link-click';
import waitOverlay from './wait-overlay/wait-overlay';
import searchPexels from './search-pexels/search-pexels';
import qrCode from './qr-code/qr-code';
import badgeTrueFalse from './badge-true-false/badge-true-false';
import selectOnClick from './select-on-click/select-on-click';
import moneyMask from './money-mask/money-mask';
import dateMask from './date-mask/date-mask';
import integerMask from './integer-mask/integer-mask';
import imageGallery from './image-gallery/image-gallery';
import topProgressBar from './top-progress-bar/top-progress-bar';
import mainFooter from './main-footer/main-footer';
import helpTip from './help-tip/help-tip';
import bell from './bell/bell';
import emoticonTags from './emoticon-tags/emoticon-tags';
import lancamentosContrato from './lancamentos-contrato/lancamentos-contrato';
import userPanel from './user-panel/user-panel';
import blockEndereco from './block-endereco/block-endereco';
import blockContas from './block-contas/block-contas';
import blockJsonTree from './block-json-tree/block-json-tree';
import searchFilter from './search-filter/search-filter';
import headerInfoCliente from './header-info-cliente/header-info-cliente';
import blockTransportadoraPagamento from './block-transportadora-pagamento/block-transportadora-pagamento';
import firestoreReference from './firestore-reference/firestore-reference';
import selectEmpresa from './select-empresa/select-empresa';
import moeda from './moeda/moeda';
import premiosCampanha from './premios-campanha/premios-campanha';
import influencersCampanha from './influencers-campanha/influencers-campanha';
import sorteiosCampanha from './sorteios-campanha/sorteios-campanha';
import sorteioCampanhaPremios from './sorteio-campanha-premios/sorteio-campanha-premios';

const ngModule = angular.module('directives', [
    loginBox.name,
    navbarTopLeft.name,
    navbarSearch.name,
    navbarLogout.name,
    mainFooter.name,
    linkClick.name,
    collectionValue.name,
    waitOverlay.name,
    searchPexels.name,
    qrCode.name,
    badgeTrueFalse.name,
    selectOnClick.name,
    moneyMask.name,
    dateMask.name,
    integerMask.name,
    imageGallery.name,
    topProgressBar.name,
    helpTip.name,
    bell.name,
    emoticonTags.name,
    userPanel.name,
    blockEndereco.name,
    blockJsonTree.name,
    blockContas.name,
    searchFilter.name,
    lancamentosContrato.name,
    headerInfoCliente.name,
    blockTransportadoraPagamento.name,
    firestoreReference.name,
    selectEmpresa.name,
    moeda.name,
    premiosCampanha.name,
    influencersCampanha.name,
    sorteiosCampanha.name,
    sorteioCampanhaPremios.name
]);

export default ngModule;
