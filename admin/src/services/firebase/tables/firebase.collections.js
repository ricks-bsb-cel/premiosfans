// import baseCollection from './firebase.base.collection';

import collectionCrud from './collections/collection.crud';

import collectionAdmConfigPath from './collections/collection.admConfigPath';
import collectionAdmConfigProfiles from './collections/collection.admConfigProfiles';

import collectionFormlySelector from './collections/collection.formlySelector';
import collectionUserProfile from './collections/collection.userProfile';

import collectionEmpresas from './collections/collection.empresas'; // Influencers

import collectionCampanhas from './collections/collection.campanhas';
import collectionCampanhasInfluencers from './collections/collection.campanhasInfluencers';
import collectionCampanhasSorteios from './collections/collection.campanhasSorteios';
import collectionCampanhasSorteiosPremios from './collections/collection.campanhasSorteiosPremios';

import collectionApiConfig from './collections/collection.apiConfig';
import collectionHtmlBlock from './collections/collection.htmlBlock';
import collectionConteudo from './collections/collection.conteudo';
import collectionLancamentos from './collections/collection.lancamentos';

import collectionEntidades from './collections/collection.entidades';

import collectionClientes from './collections/collection.clientes';

import collectionFrontTemplates from './collections/collection.front-templates';

import collectionAppLinks from './collections/collection.appLinks';

let ngModule = angular.module('firebase.collections', [
	collectionCrud.name,

	collectionAdmConfigPath.name,
	collectionAdmConfigProfiles.name,

	collectionEmpresas.name,

	collectionCampanhas.name,
	collectionCampanhasInfluencers.name,
	collectionCampanhasSorteios.name,
	collectionCampanhasSorteiosPremios.name,

	collectionClientes.name,
	collectionFormlySelector.name,
	collectionUserProfile.name,
	collectionApiConfig.name,
	collectionHtmlBlock.name,
	collectionConteudo.name,
	collectionLancamentos.name,

	collectionEntidades.name,
	collectionFrontTemplates.name,
	collectionAppLinks.name
]);

export default ngModule;