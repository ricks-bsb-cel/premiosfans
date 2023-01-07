"use strict";

const firestoreDAL = require('../api/firestoreDAL');
const _ = require('lodash');
const moment = require("moment-timezone");

const collectionTitulo = firestoreDAL.titulos();
const collectionTitulosPremios = firestoreDAL.titulosPremios();

const getById = idTitulo => {
    return new Promise((resolve, reject) => {

        const promise = [
            collectionTitulo.getDoc(idTitulo),
            collectionTitulosPremios.get({
                filter: [
                    { field: "idTitulo", condition: "==", value: idTitulo }
                ]
            })
        ];

        return Promise.all(promise)
            .then(promiseResult => {
                const titulo = promiseResult[0],
                    premios = promiseResult[1];

                const result = {
                    idTituloCompra: titulo.idTituloCompra,
                    idTitulo: titulo.id,
                    idCampanha: titulo.idCampanha,
                    campanhaNome: titulo.campanhaNome,
                    vlTitulo: titulo.campanhaVlTitulo,
                    uidComprador: titulo.uidComprador,
                    campanhaDetalhes: titulo.campanhaDetalhes,
                    campanhaSubTitulo: titulo.campanhaSubTitulo,
                    celular_formated: titulo.celular_formated,
                    cpf: titulo.cpf,
                    qtdPremios: titulo.qtdPremios,
                    cpf_formated: titulo.cpf_formated,
                    qtdNumerosGerados: titulo.qtdNumerosGerados,
                    nome: titulo.nome,
                    email: titulo.email,
                    id: titulo.id,
                    dtInclusao: moment(titulo.dtInclusao, "YYYY-MM-DD HH-mm-ss").format("DD/MM/YYYY HH:mm"),
                    sorteios: []
                };

                premios.forEach(p => {
                    const pos = result.sorteios.findIndex(f => {
                        return f.idSorteio === p.idSorteio;
                    });

                    const premio = {
                        premioDescricao: p.premioDescricao,
                        premioValor: p.premioValor,
                        numerosDaSorte: p.numerosDaSorte
                    }

                    if (pos < 0) {
                        result.sorteios.push({
                            idSorteio: p.idSorteio,
                            sorteioDtSorteio: p.sorteioDtSorteio,
                            sorteioDtSorteio_weak_day: p.sorteioDtSorteio_weak_day,
                            sorteioDtSorteio_yyyymmdd: p.sorteioDtSorteio_yyyymmdd,
                            premios: [premio]
                        })
                    } else {
                        result.sorteios[pos].premios.push(premio);
                    }
                });

                result.sorteios = _.sortBy(result.sorteios, ['sorteioDtSorteio_yyyymmdd'])
                    .map((s, i) => {
                        s.pos = i + 1;
                        return s;
                    });

                return resolve(result);
            })

            .catch(e => {
                console.error(e);

                return reject(e);
            })

    })
}

exports.getById = getById;
