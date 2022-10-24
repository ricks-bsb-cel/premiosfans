import viewAdmConfigPath from './adm-config-path/adm-config-path';
import viewAdmConfigProfiles from './adm-config-profiles/adm-config-profiles';
import viewAdmConfigProfileEdit from './adm-config-profile-edit/adm-config-profile-edit';

import viewDashboard from './dashboard/dashboard';
import viewGlobalDashboard from './global-dashboard/global-dashboard';
import viewPlanos from './planos/planos';
import viewContratos from './contratos/contratos';
import viewContratosEdit from './contratos-edit/contratos-edit';
import viewCobrancas from './cobrancas/cobrancas';
import viewGlobalWhatsapp from './global-whatsapp/global-whatsapp';
import viewMessagesReceived from './messagesReceived/messagesReceived';
import viewDashboardClientes from './dashboard-clientes/dashboard-clientes';
import viewDashboardClientesCobrancas from './dashboard-clientes-cobrancas/dashboard-clientes-cobrancas';
import viewDashbardRH from './dashboard-rh/dashboard-rh';
import viewTemplates from './_templates_/_templates_';
import viewGlobalConfig from './global-config/global-config';
import viewHtmlBlock from './html-block/html-block';
import viewConteudo from './conteudo/conteudo';
import viewProdutos from './produtos/produtos';

import viewEmpresas from './empresas/empresas';
import viewUsuarios from './usuarios/usuarios';
import viewClientes from './clientes/clientes';

let ngModule = angular.module('views', [
	viewAdmConfigPath.name,
	viewAdmConfigProfiles.name,
	viewAdmConfigProfileEdit.name,

	viewDashboard.name,
	viewDashbardRH.name,
	viewGlobalDashboard.name,
	viewPlanos.name,
	viewContratos.name,
	viewCobrancas.name,
	viewContratosEdit.name,
	viewGlobalWhatsapp.name,
	viewMessagesReceived.name,
	viewDashboardClientesCobrancas.name,
	viewTemplates.name,
	viewGlobalConfig.name,
	viewHtmlBlock.name,
	viewConteudo.name,
	viewProdutos.name,

	viewEmpresas.name,
	viewUsuarios.name,
	viewClientes.name,
	viewDashboardClientes.name
]);

export default ngModule;
