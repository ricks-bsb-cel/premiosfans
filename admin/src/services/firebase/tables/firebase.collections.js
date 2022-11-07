// import baseCollection from './firebase.base.collection';

import collectionCrud from './collections/collection.crud';

import collectionAdmConfigPath from './collections/collection.admConfigPath';
import collectionAdmConfigProfiles from './collections/collection.admConfigProfiles';

import collectionsFormlySelector from './collections/collection.formlySelector';
import collectionsUserProfile from './collections/collection.userProfile';

import collectionsEmpresas from './collections/collection.empresas'; // Influencers

import collectionsCampanhas from './collections/collection.campanhas';
import collectionsCampanhasPremios from './collections/collection.campanhasPremios';

import collectionsApiConfig from './collections/collection.apiConfig';
import collectionHtmlBlock from './collections/collection.htmlBlock';
import collectionConteudo from './collections/collection.conteudo';
import collectionLancamentos from './collections/collection.lancamentos';

import collectionEntidades from './collections/collection.entidades';

import collectionsClientes from './collections/collection.clientes';

import collectionFrontTemplates from './collections/collection.front-templates';

import collectionAppLinks from './collections/collection.appLinks';

let ngModule = angular.module('firebase.collections', [
	collectionCrud.name,

	collectionAdmConfigPath.name,
	collectionAdmConfigProfiles.name,

	collectionsEmpresas.name,

	collectionsCampanhas.name,
	collectionsCampanhasPremios.name,

	collectionsClientes.name,
	collectionsFormlySelector.name,
	collectionsUserProfile.name,
	collectionsApiConfig.name,
	collectionHtmlBlock.name,
	collectionConteudo.name,
	collectionLancamentos.name,

	collectionEntidades.name,
	collectionFrontTemplates.name,
	collectionAppLinks.name
]);

export default ngModule;