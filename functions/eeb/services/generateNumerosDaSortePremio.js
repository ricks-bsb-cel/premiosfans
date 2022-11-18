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

// Geração dos lotes
const createLotes = _ => {

    const rand = global.randomNumber(7);

    const result = {
        qtdLotes: 0,
        qtdLotesDisponiveis: 0,
        qtdLotesUtilizados: 0,
        qtdLotesEncerrados: 0,
        qtdNumerosDisponiveis: 0,
        qtdNumerosUtilizados: 0,
        lotes: {}
    };

    // Cria os 100 lotes de 1000 números cada
    for (let l = 0; l < 100; l++) {
        let numerosDaSorte = [];

        let lote = {
            codigo: l,
            qtdDisponiveis: 0,
            qtdUtilizados: 0,
            numeros: []
        };

        const codigoLote = `lote-${l.toString().padStart(2, '0')}`;

        // Carrega os 1000 números em sequencial
        for (let ns = 0; ns < 1000; ns++) {
            numerosDaSorte.push(ns);
        }

        // Shuffle

        for (let r = 0; r <= rand; r++) {
            numerosDaSorte = global.shuffleArray(numerosDaSorte);
        }

        // Adiciona no lote
        numerosDaSorte.forEach(ns => {
            lote.qtdDisponiveis++;
            lote.numeros.push({
                n: ns,
                t: 0
            })
        })

        result.qtdLotes++;
        result.qtdLotesDisponiveis++;
        result.qtdNumerosDisponiveis += lote.numeros.length;
        result.lotes[codigoLote] = lote;
    }

    return result;
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

            const result = {
                success: true,
                host: this.parm.host,
                path: `numerosDaSorte/${idCampanha}/${idPremio}`
            };

            if (!idCampanha) throw new Error(`idCampanha inválido`);
            if (!idPremio) throw new Error(`idPremio inválido`);

            // Localiza o Premio
            return collectionCampanhasSorteiosPremios.getDoc(idPremio)

                .then(premioResult => {
                    result.premio = premioResult;

                    if (result.premio.idCampanha !== idCampanha) throw new Error('O premio não pertence à campanha');

                    // Outras validações...

                    // Verifica se já não foi gerado
                    return admin.database().ref(result.path).once('value');
                })

                .then(lotesNumerosDaSorte => {
                    result.lotes = lotesNumerosDaSorte.val();

                    if (result.lotes) return null;

                    result.lotes = createLotes();


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

const call = (idCampanha, idPremio, request, response) => {

    const service = new Service(request, response, {
        name: 'generate-numeros-da-sorte-premio',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        requireIdEmpresa: false,
        data: {
            idCampanha: idCampanha,
            idPremio: idPremio
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

    if (!idCampanha || !idPremio) {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(idCampanha, idPremio, request, response);
}
