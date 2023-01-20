"use strict";

const pixStoreHelper = require('./pixStoreHelper');

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const pixStoreGenerate = require('./pixStoreGenerate');

/*
A pixStoreCheck verifica se é necessário gerar novos PIXs antecipados.
    - Carrega a configuração do PIX/Valor. Se não exitir, quer dizer que o PIX/Valor não tem PIX antecipado
    - Se a quantidade de registros disponíveis for menor do que o mínimo, gera até a quantidade máxima
*/

const schema = _ => {
    const schema = Joi.object({
        key: Joi.string().required(),
        valor: Joi.number().min(1).max(999999).required()
    });

    return schema;
}

async function pixStoreCheck(parm) {
    const valor = parm.valor.toFixed(0);

    let pixStoreConfig = await pixStoreHelper.getPixKeyConfig(parm.key);

    if (!pixStoreConfig || // Se não existir a configuração
        !pixStoreConfig.generate || // Nem as chaves de valor de geração
        !pixStoreConfig.generate[valor] // Nem a chave de valor a ser gerada
    ) return null;

    pixStoreConfig = {
        ...pixStoreConfig,
        ...pixStoreConfig.generate[valor]
    };

    delete pixStoreConfig.generate;

    let
        qtdCalls = 0,
        qtdAtual = await pixStoreHelper.getPixKeyQtd(parm.key, valor);

    const qtdMinima = pixStoreConfig.qtdMinima;
    const qtdMaxima = pixStoreConfig.qtdMaxima;

    if (qtdAtual >= qtdMinima) {
        return {
            success: true,
            ignored: true,
            message: `Quantidade atual [${qtdAtual}] maior do que a mínima exigida [${qtdMinima}]`
        }
    }

    // A quantidade atual é menor do que a qtd mínima exigida.
    const pixParm = {
        cpf: pixStoreConfig.cpf,
        accountId: pixStoreConfig.accountId,
        key: pixStoreConfig.key,
        valor: parm.valor,
        merchantCity: pixStoreConfig.merchantCity,
        additionalInfo: pixStoreConfig.additionalInfo
    };

    while (qtdAtual < qtdMaxima) {
        await pixStoreGenerate.call(pixParm);

        qtdAtual++;
        qtdCalls++;
    }

    return {
        success: true,
        ignored: false,
        message: `${qtdCalls} chamadas enfileiradas. Máximo de ${qtdMaxima}`
    };
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

    if (!data || !data.key || !data.valor) {
        if (response) {
            return response.status(500).json({ success: false, error: 'Invalid request' });
        } else {
            throw new Error('Invalid request');
        }
    }

    const service = new Service(request, response, {
        name: 'pix-store-check',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        ordered: true,
        orderingKey: data.key + '-' + data.valor.toString(),
        auth: eebAuthTypes.token,
        data: data
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
