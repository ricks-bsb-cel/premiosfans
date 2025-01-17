"use strict";

const admin = require('firebase-admin');
const eebService = require('../eventBusService').abstract;
const global = require("../../global");

const FieldValue = require('firebase-admin').firestore.FieldValue;

/*
Esta rotina recebe
    O Código da Campanha
    O Código do Premio
    Quantidade de Grupos ~ se não informado 100, começando de 0 (zero)
    Quantidade de Números por Grupo ~ se não informado 1000, começando de 0 (zero)

    E gera os lotes de números no RealTime Database, em
    /numerosDaSorte/<idCampanha>/<idPremio>
*/

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');

const collectionCampanhasSorteiosPremios = firestoreDAL.campanhasSorteiosPremios();

// Geração dos lotes
const createLotes = (qtdGrupos, qtdNumerosPorGrupo) => {

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

    let numerosLote = [];

    for (let l = 0; l < qtdGrupos; l++) {
        numerosLote.push(l);
    }

    for (let r = 0; r <= rand; r++) {
        numerosLote = global.shuffleArray(numerosLote);
    }

    // Cria os 100 lotes de 1000 números cada
    numerosLote.forEach(l => {
        let numerosDaSorte = [];

        const lote = {
            codigo: l,
            qtdDisponiveis: 0,
            qtdUtilizados: 0,
            numeros: []
        };

        const codigoLote = `lote-${global.generateRandomId(6).toLowerCase()}-${l.toString().padStart(2, '0')}`;

        // Carrega os 1000 números em sequencial
        for (let ns = 0; ns < qtdNumerosPorGrupo; ns++) {
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
    })

    return result;
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const idCampanha = this.parm.data.idCampanha;
            const idPremio = this.parm.data.idPremio;
            const force = typeof this.parm.data.force === 'boolean' ? this.parm.data.force : false;

            const qtdGrupos = this.parm.data.qtdGrupos || 100;
            const qtdNumerosPorGrupo = this.parm.data.qtdNumerosPorGrupo || 1000;

            const result = {
                success: true,
                host: this.parm.host,
                idCampanha: idCampanha,
                idPremio: idPremio,
                force: force,
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
                    return force ? null : admin.database().ref(result.path).once('value');
                })

                .then(lotesNumerosDaSorte => {
                    result.data = lotesNumerosDaSorte ? lotesNumerosDaSorte.val() : null;

                    if (result.data) return null;

                    result.data = createLotes(qtdGrupos, qtdNumerosPorGrupo);

                    // Salva no RealTime
                    return admin.database().ref(result.path).set(result.data);
                })

                .then(_ => {
                    // Atualiza o contador de Geração de Números da Sorte dos Premios na Campanha
                    return admin.firestore().collection('campanhas').doc(idCampanha).set({
                        qtdPremiosNumerosDaSorteGerados: FieldValue.increment(1)
                    }, { merge: true })
                })

                .then(_ => {
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

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    if (!data) throw new Error('invalid parms');
    if (!data.idCampanha) throw new Error('Informe idCampanha');
    if (!data.idPremio) throw new Error('Informe idCampanha');

    data.qtdGrupos = data.qtdGrupos || 100;
    data.qtdNumerosPorGrupo = data.qtdNumerosPorGrupo || 1000;
    data.force = typeof data.force === 'boolean' ? data.force : false;

    const service = new Service(request, response, {
        name: 'generate-numeros-da-sorte-premio',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        data: data,
        auth: eebAuthTypes.internal
    });

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    const data = {
        idCampanha: request.body.idCampanha,
        idPremio: request.body.idPremio,
        qtdGrupos: request.body.qtdGrupos || 100,
        qtdNumerosPorGrupo: request.body.qtdNumerosPorGrupo || 1000,
        force: typeof request.body.force === 'boolean' ? request.body.force : false
    }

    const host = global.getHost(request);

    if (!data.idCampanha || !data.idPremio || host !== 'localhost') {
        return response.status(500).json({
            success: false,
            error: 'Invalid parms'
        })
    }

    return call(data, request, response);
}
