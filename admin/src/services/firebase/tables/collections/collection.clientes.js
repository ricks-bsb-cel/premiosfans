'use strict';

const ngModule = angular.module('collection.clientes', [])

    .factory('collectionClientes', function (
        appErrors,
        globalFactory,
        appAuthHelper,
        appFirestoreHelper,
        appCollection,
        $q
    ) {

        const attr = {
            collection: 'clientes',
            autoStartSnapshot: false,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const keywords = cliente => {
            return globalFactory.generateKeywords(
                cliente.nome,
                cliente.email,
                cliente.cpfcnpj,
                cliente.celular
            );
        }

        const getClienteByCpfCnpj = cpfcnpj => {
            return $q(function (resolve, reject) {

                var queryCpfCnpj = appFirestoreHelper.collection('clientes');

                appAuthHelper.ready()

                    .then(_ => {
                        queryCpfCnpj = appFirestoreHelper.query(queryCpfCnpj, 'idEmpresa', '==', appAuthHelper.profile.user.idEmpresa);
                        queryCpfCnpj = appFirestoreHelper.query(queryCpfCnpj, 'cpfcnpj', '==', cpfcnpj);
                        return appFirestoreHelper.docs(queryCpfCnpj);
                    })

                    .then(clientes => {
                        return resolve(clientes);
                    })

                    .catch(e => {
                        console.error(e);
                        return reject(e);
                    })
            })
        }

        const save = function (data) {
            return $q(function (resolve, reject) {

                var id = data.id || 'new';
                var update = null;

                appAuthHelper.ready()

                    .then(_ => {

                        update = {
                            cpf: data.cpfcnpj_type === 'PF' ? data.cpf || data.cpfcnpj : null,
                            cpf_formatted: data.cpfcnpj_type === 'PF' ? data.cpf_formatted || data.cpfcnpj_formatted : null,

                            cnpj: data.cpfcnpj_type === 'PJ' ? data.cpfcnpj : null,
                            cnpj_formatted: data.cpfcnpj_type === 'PJ' ? data.cpfcnpj_formatted : null,

                            cpfcnpj: data.cpfcnpj,
                            cpfcnpj_type: data.cpfcnpj_type,
                            cpfcnpj_formatted: data.cpfcnpj_formatted,

                            idEmpresa: appAuthHelper.profile.user.idEmpresa,
                            idEmpresa_reference: appFirestoreHelper.doc('empresas', appAuthHelper.profile.user.idEmpresa),
                            idUser: appAuthHelper.user.uid,
                            nome: data.nome,

                            keywords: keywords(data),

                            endereco_cliente_bairro: data.endereco_cliente_bairro || null,
                            endereco_cliente_cep: data.endereco_cliente_cep || null,
                            endereco_cliente_cidade: data.endereco_cliente_cidade || null,
                            endereco_cliente_complemento: data.endereco_cliente_complemento || null,
                            endereco_cliente_estado: data.endereco_cliente_estado || null,
                            endereco_cliente_numero: data.endereco_cliente_numero || null,
                            endereco_cliente_rua: data.endereco_cliente_rua || null,

                            ignorarEndereco: typeof data.ignorarEndereco === 'boolean' ? data.ignorarEndereco : true,

                            isFakeData: typeof data.isFakeData === 'boolean' ? data.isFakeData : false,
                            dtAlteracao: appFirestoreHelper.currentTimestamp()
                        };

                        if (data.email) {
                            update.email = data.email;
                        }

                        if (data.celular) {
                            update.celular = data.celular;
                            update.celular_formatted = data.celular_formatted;
                            update.celular_int = data.celular_int;
                            update.celular_intplus = data.celular_intplus;
                        }

                        if (id === 'new') {
                            update.dtInclusao = appFirestoreHelper.currentTimestamp();
                        }

                        return getClienteByCpfCnpj(update.cpfcnpj);
                    })

                    .then(ClientesMesmoCpfCnpj => {

                        if (id !== 'new') {
                            ClientesMesmoCpfCnpj = ClientesMesmoCpfCnpj.filter(f => { return f.id !== id; });
                        }

                        if (ClientesMesmoCpfCnpj.length > 0) {
                            throw new Error('Já existe um cliente cadastrado para esta empresa com o mesmo CPF ou CNPJ.');
                        }

                        return firebaseCollection.addOrUpdateDoc(id, update);
                    })

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(e => {
                        appErrors.showError(e, attr.collection);
                        return reject(e);
                    })

            })
        }

        /*
        const reindex = function () {

            if (onIndex) {
                toastrFactory.error('Uma indexação já está em andamento...');
                return;
            } else {
                toastrFactory.success('Iniciando indexação de clientes...');
            }

            onIndex = true;
            var qtdAtualiados = 0;
            const collection = firebaseProvider.firestore.collection("clientes");
            const hoje = firebaseProvider.firebase.firestore.Timestamp.now();

            const updateNextDoc = function () {

                collection
                    .where('idEmpresa', '==', userProfileFactory.profile.idEmpresaAtual)
                    .where('dtAlteracao', '<', hoje)
                    .limit(1)
                    .get()
                    .then(clientes => {

                        if (clientes.empty) {
                            onIndex = false;
                            alertFactory.success('Fim da indexação de Clientes: ' + qtdAtualiados + ' documentos atualizados...');
                        }

                        clientes.forEach(c => {

                            c = angular.merge(c.data(), { id: c.id });

                            collection.doc(c.id).update({
                                dtAlteracao: hoje,
                                keywords: keywords(c)
                            }).then(() => {
                                qtdAtualiados++;
                                updateNextDoc();
                            }).catch(e => {
                                console.error(e);
                                alertFactory.error(e);
                            })

                        })
                    }).catch(e => {
                        console.error(e);
                        alertFactory.error(e);
                    })
            }

            updateNextDoc();

        }

        const deleteFakeData = function (idEmpresa, confirm, callback) {
            firebaseCollection.removeFakeData(idEmpresa, confirm, callback);
        }
        */

        return {
            collection: firebaseCollection,
            save: save
            // reindex: reindex,
            // deleteFakeData: deleteFakeData
        };

    });

export default ngModule;
