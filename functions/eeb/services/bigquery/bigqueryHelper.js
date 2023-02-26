"use strict";

const bigqueryTables = require('./bigqueryTables');

async function createTableOnBigQuery(tableType, datasetId, tableName) {
    try {
        const tableStruct = bigqueryTables.getStructure(tableType, datasetId, tableName);

        // Garante que o dataset exista
        const { BigQuery } = require('@google-cloud/bigquery');
        const bigquery = new BigQuery();

        const dataset = bigquery.dataset(datasetId);
        await dataset.get({ autoCreate: true });

        const [job] = await bigquery.createQueryJob({
            query: tableStruct.createTable,
        });

        await job.getQueryResults();

        return true;
    } catch (e) {
        throw new Error(`Erro na criação do DataSet ou Tabela: ${e.message}`);
    }
}

async function addRow(parm) {
    const { BigQuery } = require('@google-cloud/bigquery');
    const bigquery = new BigQuery();

    try {
        await bigquery.dataset(parm.datasetId).table(parm.tableName).insert(parm.row || parm.rows);

        return true;
    } catch (e) {
        if (e.code === 404) {
            console.info(`Dataset ${parm.datasetId} e/ou tabela ${parm.tableName} não encontrados. Criando...`);

            await createTableOnBigQuery(parm.tableType, parm.datasetId, parm.tableName);

            e.code = 404;
            e.message = `O dataset ${parm.datasetId} e/ou tabela ${parm.tableName} foram criado com exito. Tente novamente...`;

            throw e;
        } else {
            console.error(e.message);
            if (e.errors) console.error(JSON.stringify(e.errors));

            throw e;
        }
    }
}

exports.addRow = addRow;
