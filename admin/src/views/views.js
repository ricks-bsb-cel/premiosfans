import viewAdmConfigPath from './adm-config-path/adm-config-path';
import viewAdmConfigProfiles from './adm-config-profiles/adm-config-profiles';
import viewAdmConfigProfileEdit from './adm-config-profile-edit/adm-config-profile-edit';

import viewDashboard from './dashboard/dashboard';
import viewGlobalDashboard from './global-dashboard/global-dashboard';
import viewPlanos from './planos/planos';
import viewCampanhas from './campanhas/campanhas';
import viewCampanhasEdit from './campanhas-edit/campanhas-edit';
import viewCobrancas from './cobrancas/cobrancas';
import viewGlobalWhatsapp from './global-whatsapp/global-whatsapp';
import viewMessagesReceived from './messagesReceived/messagesReceived';
import viewDashboardClientes from './dashboard-clientes/dashboard-clientes';
import viewDashboardClientesCobrancas from './dashboard-clientes-cobrancas/dashboard-clientes-cobrancas';
import viewDashbardRH from './dashboard-rh/dashboard-rh';
import viewTemplates from './_templates_/_templates_';
import viewGlobalConfig from './global-config/global-config';
import viewHtmlBlock from './html-block/html-block';
import viewProdutos from './produtos/produtos';

import viewAppLinks from './app-links/app-links';

// import viewEmpresas from './empresas/empresas';
import viewInfluencers from './influencers/influencers';	// Cópia da viewEmpresas
import viewUsuarios from './usuarios/usuarios';
import viewClientes from './clientes/clientes';

import viewTitulos from './titulos/titulos';
import viewTitulosCompras from './titulos-compras/titulos-compras';
import viewTitulosPremios from './titulos-premios/titulos-premios';

import viewContas from './contas/contas';
import viewContasEdit from './contas-edit/contas-edit';

import viewFaq from './faq/faq';

import viewCartosAdmin from './cartos/cartos-admin/cartos-admin';
import viewCartosAccounts from './cartos/cartos-accounts/cartos-accounts';
import viewCartosPixKeys from './cartos/cartos-pix-keys/cartos-pix-keys';

let ngModule = angular.module('views', [
	viewAdmConfigPath.name,
	viewAdmConfigProfiles.name,
	viewAdmConfigProfileEdit.name,

	// viewEmpresas.name,
	viewInfluencers.name,	// Cópia da viewEmpresas
	viewUsuarios.name,

	viewDashboard.name,
	viewDashbardRH.name,
	viewGlobalDashboard.name,

	viewCampanhas.name,
	viewCampanhasEdit.name,

	viewPlanos.name,
	viewCobrancas.name,
	viewGlobalWhatsapp.name,
	viewMessagesReceived.name,
	viewDashboardClientesCobrancas.name,
	viewTemplates.name,
	viewGlobalConfig.name,
	viewHtmlBlock.name,
	viewProdutos.name,
	viewAppLinks.name,

	viewClientes.name,
	viewDashboardClientes.name,

	viewTitulos.name,
	viewTitulosCompras.name,
	viewTitulosPremios.name,

	viewContas.name,
	viewContasEdit.name,
	viewFaq.name,

	viewCartosAdmin.name,
	viewCartosAccounts.name,
	viewCartosPixKeys.name
]);

export default ngModule;
