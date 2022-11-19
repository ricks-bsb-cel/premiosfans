"use strict";

const admin = require('firebase-admin');
const path = require('path');
const eebService = require('../eventBusService').abstract;
const global = require("../../global");

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

// Receber no parametro um guidTitulo e idInfluencer (obrigatórios)
// Pesquisar e criar o título se não existir
// Cada chamada do generateTitulo gera um número da sorte e grava no título
// Se são 2 números, esta rotina deve ser chamada 2 vezes
// Esta rotina sofre retentativa automática. Se houver colisão com outra geração, não tentar novamente na rotinas
// Lembre-se que esta rotina deve ser chamada uma vez para cada número da sorte de cada premio de cada titulos
// Se chamar mais do que a quantidade de números da sorte do premio, ignora
// Todo título tem o mesmo guidTitulo para todos os seus premios

const findLote = path => {
    return new Promise((resolve, reject) => {
        const ref = admin.database().ref(path);
        const query = ref.orderByChild('qtdDisponiveis').limitToLast(1);

        return query.on('value', data => {
            data = data.val();

            if (!data || typeof data !== 'object') {
                return reject(new Error(`Não existe nenhum lote de números gerados para o premio`));
            }

            return resolve(Object.keys(data)[0]);
        })
    })
}

const getNumero = (path, idTitulo) => {
    return new Promise((resolve, reject) => {
        const result = {};

        return findLote(path)

            .then(lote => {
                result.idLote = lote;

                return admin.database().ref(`${result.path}/lotes/${lote}`).transaction(data => {
                    if (data.qtdDisponiveis && data.qtdDisponiveis > 0) {
                        data.qtdDisponiveis--;
                        data.qtdUtilizados++;

                        const pos = data.numeros.findIndex(f => { return f.t === 0; });

                        if (pos >= 0) {
                            result.lote = data.codigo;
                            result.numero = data.codigo.toString().padStart(2, '0') + data.numeros[pos].n.toString().padStart(3, '0');
                            data.numeros[pos].t = idTitulo;
                        }
                    }

                    result.qtdDisponiveis = data.qtdDisponiveis;
                    result.qtdUtilizados = data.qtdUtilizados;

                    return data;
                });
            })

            .then(transactionResult => {
                if (!transactionResult.committed) {
                    throw new Error('Transaction error...');
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const idCampanha = this.parm.data.idCampanha;
            const idPremio = this.parm.data.idPremio;
            let qtdNumeros = this.parm.data.qtdNumeros;

            const result = {
                success: true,
                host: this.parm.host,
                idCampanha: idCampanha,
                idPremio: idPremio,
                path: `numerosDaSorte/${idCampanha}/${idPremio}`
            };

            if (!idCampanha) throw new Error(`idCampanha inválido`);
            if (!idPremio) throw new Error(`idPremio inválido`);

            return collectionCampanhasSorteiosPremios.getDoc(idPremio)

                .then(premioResult => {
                    result.premio = premioResult;

                    if (result.premio.idCampanha !== idCampanha) throw new Error('O premio não pertence à campanha');

                    return getNumero(result.path);
                })

                .then(getNumeroResult => {
                    result.numero = getNumeroResult;

                    delete result.premio;

                    return resolve(this.parm.async ? { success: true } : result);
                })

                .catch(e => {
                    console.error(e);

                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (idCampanha, idPremio, qtdNumeros, request, response) => {

    const service = new Service(request, response, {
        name: 'generate-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        requireIdEmpresa: false,
        data: {
            idCampanha: idCampanha,
            idPremio: idPremio,
            qtdNumeros: qtdNumeros
        },
        attributes: {
            idEmpresa: idCampanha
        }
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const idCampanha = request.body.idCampanha;
    const idPremio = request.body.idPremio;
    const qtdNumeros = request.body.qtdNumeros || 2;

    if (!idCampanha || !idPremio || !qtdNumeros || typeof qtdNumeros !== 'number') {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idCampanha, idPremio, qtdNumeros, request, response);
}
