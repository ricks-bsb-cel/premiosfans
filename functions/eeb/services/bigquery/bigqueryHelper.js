"use strict";

const admin = require("firebase-admin");
const { BigQuery } = require('@google-cloud/bigquery');
const bigquery = new BigQuery();
const global = require('../../../global');

const bigqueryTables = require('./bigqueryTables');

async function createTableOnBigQuery(datasetId, tableName) {
    let dataset;

    try {
        // Garante que o dataset exista
        dataset = bigquery.dataset(datasetId);
        dataset = await dataset.get({ autoCreate: true });

        const table = await bigquery.dataset(datasetId).createTable(tableName, tableStruct);

        return;
    } catch (error) {
        throw new Error(`Table or Dataset creation failed: ${error.message}`);
    }
}

const getTable = (datasetId, tableName, tableStruct) => {
    const
        path = `bigQueryTablesStatus/${datasetId}/${tableName}`,
        ref = admin.database().ref(path);

    let
        dataset,
        result = null;

    return new Promise((resolve, reject) => {

        const tableStruct = bigqueryTables.getStructure(datasetId, tableName);

        return ref.once("value")

            .then(data => {
                result = data.val() || null;

                if (result && result.status === 'ready') {
                    return;
                }

                if (result && result.status === 'creating') {
                    throw new Error('A tabela está sendo criada...')
                }

                return ref.transaction(data => {

                    if (data && data.status === 'creating') {
                        // Já existe registro de controle da tabela, mas a tabela ainda está sendo criada
                        throw new Error('A tabela está sendo criada...');
                    }

                    if (!data) {
                        // Ainda não existe registro de controle da tabela
                        result = {
                            status: 'creating',
                            dtCreating: global.getToday()
                        };

                        data = result;

                        return data;
                    }

                })

            })

            .then(transactionResult => {
                if (result && result.status === 'creating' && transactionResult.committed) {
                    // Tudo pronto para a criação da tabela no BigQuery
                    return createTableOnBigQuery(datasetId, tableName, tableStruct);
                }

                if (result && result.status === 'ready') {
                    return;
                }

                throw new Error('Unknnow error');
            })

            .then(_ => {
                if (result && result.status === 'creating') {
                    result = {
                        status: 'ready',
                        dtReady: global.getToday()
                    }

                    return ref.update(result);
                }

                return;
            })

            .then(_ => {
                return bigquery.dataset(datasetId).table(tableName);
            })

            .catch(e => {
                console.error(e);

                return reject(e);
            })
    })
}

exports.getTable = getTable;