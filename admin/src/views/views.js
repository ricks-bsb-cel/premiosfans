import viewAdmConfigPath from './adm-config-path/adm-config-path';
import viewAdmConfigProfiles from './adm-config-profiles/adm-config-profiles';
import viewAdmConfigProfileEdit from './adm-config-profile-edit/adm-config-profile-edit';

import viewDashboard from './dashboard/dashboard';
import viewGlobalDashboard from './global-dashboard/global-dashboard';
import viewPlanos from './planos/planos';
import viewContratos from './contratos/contratos';
import viewContratosEdit from './contratos-edit/contratos-edit';
import viewCobrancas from './cobrancas/cobrancas';
import viewVault from './vault/vault';
import viewGlobalWhatsapp from './global-whatsapp/global-whatsapp';
import viewMessagesReceived from './messagesReceived/messagesReceived';
import viewDashboardClientes from './dashboard-clientes/dashboard-clientes';
import viewDashboardClientesCobrancas from './dashboard-clientes-cobrancas/dashboard-clientes-cobrancas';
import viewDashbardRH from './dashboard-rh/dashboard-rh';
import viewTemplates from './_templates_/_templates_';
import viewGlobalConfig from './global-config/global-config';
import viewApiConfig from './api-config/api-config';
import viewContas from './contas/contas';
import viewTransacoes from './transacoes/transacoes';
import viewChavesPix from './chaves-pix/chaves-pix';
import viewHtmlBlock from './html-block/html-block';
import viewConteudo from './conteudo/conteudo';
import viewZoeAccounts from './zoe-accounts/zoe-accounts';
import viewProdutos from './produtos/produtos';

import viewEntidades from './entidades/entidades';

// Entidades substitui o seguinte (no mínimo!):
import viewFolhaFuncionarios from './folha/funcionarios/funcionarios';
import viewEmpresas from './empresas/empresas';
import viewUsuarios from './usuarios/usuarios';
import viewClientes from './clientes/clientes';


import viewFolhaImportacoes from './folha/importacoes/importacoes';
import viewFolhaPagamentos from './folha/pagamentos/pagamentos';
import viewFolhaImportacaoFuncionarios from './folha/importacao-funcionarios/importacao-funcionarios';
import viewFolhaItensContraCheque from './folha/itens-contracheque/itens-contracheque';

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
	viewVault.name,
	viewGlobalWhatsapp.name,
	viewMessagesReceived.name,
	viewDashboardClientesCobrancas.name,
	viewTemplates.name,
	viewGlobalConfig.name,
	viewApiConfig.name,
	viewContas.name,
	viewTransacoes.name,
	viewChavesPix.name,
	viewHtmlBlock.name,
	viewConteudo.name,
	viewZoeAccounts.name,
	viewProdutos.name,
	
	viewFolhaFuncionarios.name,
	viewFolhaImportacoes.name,
	viewFolhaPagamentos.name,
	viewFolhaImportacaoFuncionarios.name,
	viewFolhaItensContraCheque.name,

	viewEmpresas.name,
	viewUsuarios.name,
	viewClientes.name,
	viewDashboardClientes.name,

	viewEntidades.name
]);

export default ngModule;
