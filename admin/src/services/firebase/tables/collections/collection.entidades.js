'use strict';

const ngModule = angular.module('collection.entidades', [])

    .factory('collectionEntidades', function (
        appCollection,
        appAuthHelper,
        appFirestoreHelper,
        $q
    ) {
        const attr = {
            collection: 'entidades',
            autoStartSnapshot: false,
            filterEmpresa: true
        };

        var firebaseCollection = new appCollection(attr);

        const save = (data, type) => {
            return $q((resolve, reject) => {

                let update = null,
                    id = data.id || 'new';

                appAuthHelper.ready()

                    .then(_ => {

                        update = {
                            "ativo": data.ativo,
                            "cpfcnpj": data.cpfcnpj,
                            "cpfcnpj_formatted": data.cpfcnpj_formatted,
                            "nome": data.nome,
                            "celular_formatted": data.celular_formatted,
                            "celular": data.celular,
                            "celular_int": data.celular_int,
                            "celular_intplus": data.celular_intplus,
                            "email": data.email,
                            "endereco_cep": data.endereco_cep,
                            "endereco_rua": data.endereco_rua,
                            "endereco_bairro": data.endereco_bairro,
                            "endereco_cidade": data.endereco_cidade,
                            "endereco_estado": data.endereco_estado,
                            "endereco_complemento": data.endereco_complemento || null
                        };

                        if (data.dtNascimento) {
                            update.dtNascimento = data.dtNascimento;
                            update.dtNascimento_ddmmyyyy = data.dtNascimento_ddmmyyyy;
                        }

                        update[`is${type}`] = true;
                        update.idEmpresa = data.idEmpresa || [];

                        if (!update.idEmpresa.includes(appAuthHelper.profile.user.idEmpresa)) {
                            update.idEmpresa.push(appAuthHelper.profile.user.idEmpresa);
                        }

                        if (id === 'new') {
                            update.dtInclusao = appFirestoreHelper.currentTimestamp();
                        }

                        return firebaseCollection.addOrUpdateDoc(id, update);
                    })

                    .then(data => {
                        return resolve(data);
                    })

                    .catch(e => {
                        console.error(e);
                        console.info(update);
                        return reject(e);
                    })

            })
        }

        return {
            collection: firebaseCollection,
            save: save
        };
    });

export default ngModule;
