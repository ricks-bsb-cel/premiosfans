// import baseCollection from './firebase.base.collection';

import collectionCrud from './collections/collection.crud';

import collectionAdmConfigPath from './collections/collection.admConfigPath';
import collectionAdmConfigProfiles from './collections/collection.admConfigProfiles';

import collectionsFormlySelector from './collections/collection.formlySelector';
import collectionsPlanos from './collections/collection.planos';
import collectionsUserProfile from './collections/collection.userProfile';

import collectionsEmpresas from './collections/collection.empresas'; // Influencers

import collectionsCampanhas from './collections/collection.campanhas';
import collectionsCampanhasPremios from './collections/collection.campanhasPremios';

import collectionsCobrancas from './collections/collection.cobrancas';
import collectionsVault from './collections/collection.vault';
import collectionsWebhooks from './collections/collection.webHook';
import collectionsApiConfig from './collections/collection.apiConfig';
import collectionContas from './collections/collection.contas';
import collectionTransacoes from './collections/collection.transacoes';
import collectionChavesPix from './collections/collection.chaves-pix';
import collectionHtmlBlock from './collections/collection.htmlBlock';
import collectionConteudo from './collections/collection.conteudo';
import collecitonProdutos from './collections/collection.produtos';
import collectionItensContraCheque from './collections/collection.itensContraCheque';
import collectionLancamentos from './collections/collection.lancamentos';

import collectionEntidades from './collections/collection.entidades';

import collectionsClientes from './collections/collection.clientes';
import collectionFuncionarios from './collections/collection.funcionarios';
import collectionZoeAccounts from './collections/collection.zoeAccounts';


let ngModule = angular.module('firebase.collections', [
	collectionCrud.name,

	collectionAdmConfigPath.name,
	collectionAdmConfigProfiles.name,

	collectionsEmpresas.name,

	collectionsCampanhas.name,
	collectionsCampanhasPremios.name,

	collectionsClientes.name,
	collectionsFormlySelector.name,
	collectionsPlanos.name,
	collectionsUserProfile.name,
	collectionsCobrancas.name,
	collectionsVault.name,
	collectionsWebhooks.name,
	collectionsApiConfig.name,
	collectionContas.name,
	collectionTransacoes.name,
	collectionChavesPix.name,
	collectionFuncionarios.name,
	collectionHtmlBlock.name,
	collectionConteudo.name,
	collectionZoeAccounts.name,
	collectionItensContraCheque.name,
	collecitonProdutos.name,
	collectionLancamentos.name,

	collectionEntidades.name
]);

export default ngModule;