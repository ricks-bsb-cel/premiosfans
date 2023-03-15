'use strict';

const ngModule = angular.module('collection.campanhas', [])

    .factory('collectionCampanhas', function (
        appCollection,
        appFirestoreHelper,
        appAuthHelper,
        globalFactory,
        $q,

        collectionCampanhasInfluencers,
        collectionCampanhasSorteios,
        collectionCampanhasSorteiosPremios
    ) {

        const attr = {
            collection: 'campanhas',
            filterEmpresa: false
        };

        var firebaseCollection = new appCollection(attr);

        async function get(idCampanha) {

            const getData = await Promise.all([
                appFirestoreHelper.getDoc(attr.collection, idCampanha),
                collectionCampanhasInfluencers.get(idCampanha),
                collectionCampanhasSorteios.get(idCampanha),
                collectionCampanhasSorteiosPremios.get(idCampanha)
            ]);

            let campanha = getData[0],
                influencers = getData[1],
                sorteios = getData[2],
                premios = getData[3];

            if (!sorteios || sorteios.length === 0) {
                sorteios.push({
                    ativo: false,
                    idCampanha: campanha.id,
                    guidSorteio: globalFactory.guid(),
                    deleted: false,
                    premios: []
                })
            }

            campanha.influencers = influencers;
            campanha.sorteios = globalFactory.sortArray(sorteios, 'dtSorteio_yyyymmdd');

            campanha.qtdGrupos = campanha.qtdGrupos || 100;
            campanha.qtdNumerosPorGrupo = campanha.qtdNumerosPorGrupo || 1000;

            campanha.sorteios = campanha.sorteios.map(s => {
                s.premios = premios.filter(f => {
                    return f.idSorteio === s.id;
                }).map(p => {
                    p.deleted = false;
                    return p;
                });

                s.premios = globalFactory.sortArray(s.premios, 'pos');
                s.deleted = false;

                return s;
            });

            return campanha;
        }

        async function save(campanha) {

            let result = {},
                toSave = { ...campanha }; // Não modifique o objeto que está no AngularJS...

            toSave = sanitize(toSave);

            let id = toSave.id || 'new';

            delete toSave.id;

            result.campanha = await firebaseCollection.addOrUpdateDoc(id, toSave);
            result.sorteios = await collectionCampanhasSorteios.save(result.campanha, campanha.sorteios);
            // result.influencers = await collectionCampanhasInfluencers.save(result.campanha, campanha.influencers);

            await removeDeletedSorteios(campanha);

            return result;
        }

        const sanitize = campanha => {

            if (!campanha.titulo) throw new Error(`O nome da campanha é obrigatório`);
            // if (!campanha.url) throw new Error(`A URL da campanha é obrigatório`);
            if (!campanha.template) throw new Error(`O Template da campanha é obrigatório`);
            if (!campanha.vlTitulo) throw new Error(`O Valor do Título é obrigatório`);
            if (!campanha.qtdNumerosDaSortePorTitulo) throw new Error(`A quantidade de números da sorte por título é obrigatório`);

            if (!campanha.pixKeyCredito) throw new Error(`A Chave PIX que de Crédito é obrigatória`);

            let result = {
                id: campanha.id || 'new',
                ativo: typeof campanha.ativo === 'boolean' ? campanha.ativo : false,
                guidCampanha: campanha.guidCampanha || globalFactory.guid(),
                titulo: campanha.titulo,
                subTitulo: campanha.subTitulo || null,
                detalhes: campanha.detalhes || null,
                template: campanha.template,
                // url: campanha.url,
                vlTitulo: campanha.vlTitulo,
                qtdNumerosDaSortePorTitulo: campanha.qtdNumerosDaSortePorTitulo,
                qtdSorteios: 0,
                qtdPremios: 0,
                vlTotal: 0,
                qtdGrupos: campanha.qtdGrupos,
                qtdNumerosPorGrupo: campanha.qtdNumerosPorGrupo,
                termos: campanha.termos || null,
                politica: campanha.politica || null,
                rodape: campanha.rodape || null,
                regulamento: campanha.regulamento || null,

                pixKeyCredito: campanha.pixKeyCredito,
                pixKeyCredito_accountId: campanha.pixKeyCredito_accountId,
                pixKeyCredito_cpf: campanha.pixKeyCredito_cpf,
                pixKeyCredito_type: campanha.pixKeyCredito_type
            };

            campanha.sorteios.forEach(s => {
                result.qtdSorteios++;
                s.premios.forEach(p => {
                    result.qtdPremios++;
                    result.vlTotal = parseFloat((parseFloat(result.vlTotal) + parseFloat(p.valor)).toFixed(2))
                })
            })

            if (campanha.images && campanha.images.length) {
                result.images = campanha.images
                    .map(i => {
                        delete i.$$hashKey;
                        delete i.created_at;
                        delete i.featured;

                        return i;
                    })
            }

            if (result.id === 'new') {
                result.uidInclusao = appAuthHelper.user.uid;
                result.dtInclusao = appFirestoreHelper.currentTimestamp();
            }

            result.uidAlteracao = appAuthHelper.user.uid;
            result.dtAlteracao = appFirestoreHelper.currentTimestamp();

            result.keywords = globalFactory.generateKeywords(result.titulo, result.detalhe, result.url);

            return result;
        }

        const removeDeletedSorteios = campanha => {
            // Remove os sorteios quer foram excluídos pelo usuário
            return $q((resolve, reject) => {

                let promises = [];

                campanha.sorteios
                    .filter(f => {
                        return !f.ativo && f.deleted && f.id !== 'new';
                    })
                    .forEach(s => {
                        promises.push(collectionCampanhasSorteios.collection.removeDoc(s.id));
                    });

                return Promise.all(promises)

                    .then(_ => {
                        return resolve();
                    })

                    .catch(e => {
                        console.error(e);

                        return reject();
                    })
            })
        }


        return {
            collection: firebaseCollection,
            get: get,
            save: save
        };

    });


export default ngModule;
