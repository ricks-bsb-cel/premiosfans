"use strict";

const admin = require('firebase-admin');

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

/*
A pixStoreCheck verifica se é necessário iniciar a rotina de geração de PIX antecipados.
Ela faz isso da seguinte forma:
- Recebe a chave PIX e o Valor (em centavos)
- Procura no RTDB /pixStore/<chavepix>/config/generate/<valor>
- Se não localizar, não faz nada... cai fora com 200 (foda-se)
- Se localizar, Procura o total atual de registros de pagamento PIX já gerados no RTDB /pixStore/<chavepix>/qtd/<valor>/qtdAtual (default 0)
- Se a qtdAtual for menor ou igual á /pixStore/<chavepix>/config/generate/<valor>/qtdMinima, envia para o EEB o método
pixStoreGenerate N vezes até atingir /pixStore/<chavepix>/config/generate/<valor>/qtdMaxima
- e, retorna 200. Esta rotina SEMPRE retorna 200...
*/

// const firestoreDAL = require('../../api/firestoreDAL');

const schema = _ => {
    const schema = Joi.object({
        key: Joi.string().required(),
        valor: Joi.number().min(1).max(999999).required()
    });

    return schema;
}

async function pixStoreCheck(parm) {
    const valor = parm.valor.toFixed(0);
    const query = admin.database().ref(`/pixStore/${parm.key}/config`);

    let pixStoreConfig = await query.once("value");
    pixStoreConfig = pixStoreConfig.val() || null;

    if (!pixStoreConfig || !pixStoreConfig.generate || !pixStoreConfig.generate[valor]) return null;

    pixStoreConfig = {
        ...pixStoreConfig,
        ...pixStoreConfig.generate[valor]
    };

    delete pixStoreConfig.generate;

    return pixStoreConfig;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            let result = {
                success: true
            };

            return schema().validateAsync(this.parm.data)

                .then(dataResult => {
                    result.parm = dataResult;

                    return pixStoreCheck(result.parm)
                })

                .then(pixStoreConfigResult => {
                    result = {
                        success: true,
                        pixStoreConfig: pixStoreConfigResult
                    };

                    return resolve(result);
                })

                .catch(e => {
                    console.error(e);

                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const service = new Service(request, response, {
        name: 'pix-store-check',
        async: request && request.query.async ? request.query.async === 'true' : false,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
