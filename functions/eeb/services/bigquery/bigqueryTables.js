"use strict";

const _ = require("lodash");

// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types?hl=pt-br

// Especificação dos tipos de tabelas
const tablesStructures = {
    "bigQueryTableCompras": { // Todas as compras, inclusive as não pagas
        "createTable": `CREATE TABLE {datasetId}.{tableName} (
            idCompra STRING(28) NOT NULL,
            idCampanha STRING(28) NOT NULL,
            idInfluencer STRING(28) NOT NULL,
            qtdPremios INT64 NOT NULL,
            campanhaQtdNumerosDaSortePorTitulo INT64 NOT NULL,
            campanhaNome STRING NOT NULL,
            campanhaSubTitulo STRING,
            campanhaDetalhes STRING,
            campanhaVlTitulo NUMERIC(15,2) NOT NULL,
            vlTotalCompra NUMERIC(15,2) NOT NULL,
            campanhaQtdPremios INT64 NOT NULL,
            campanhaTemplate STRING NOT NULL,
            guidCompra STRING NOT NULL,
            qtdTitulosCompra INT64 NOT NULL,
            uidComprador STRING NOT NULL,
            pixKeyCredito STRING NOT NULL,
            pixKeyCpf STRING NOT NULL,
            pixKeyAccountId STRING NOT NULL,
            qtdTotalProcessos INT64 NOT NULL,

            compradorCPF STRING NOT NULL,
            compradorNome STRING,
            compradorEmail STRING,
            compradorCelular STRING,

            dtInclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL
        )`
    },
    "bigQueryTableComprasPagas": { // Apenas as compras pagas,
        "createTable": `CREATE TABLE {datasetId}.{tableName} (
            idCompra STRING(28) NOT NULL,
            idCampanha STRING(28) NOT NULL,
            idInfluencer STRING(28) NOT NULL,
            qtdPremios INT64 NOT NULL,
            campanhaQtdNumerosDaSortePorTitulo INT64 NOT NULL,
            campanhaNome STRING NOT NULL,
            campanhaSubTitulo STRING,
            campanhaDetalhes STRING,
            campanhaVlTitulo NUMERIC(15,2) NOT NULL,
            vlTotalCompra NUMERIC(15,2) NOT NULL,
            campanhaQtdPremios INT64 NOT NULL,
            campanhaTemplate STRING NOT NULL,
            guidCompra STRING NOT NULL,
            qtdTitulosCompra INT64 NOT NULL,
            uidComprador STRING NOT NULL,

            pixKeyCredito STRING NOT NULL,
            pixKeyCpf STRING NOT NULL,
            pixKeyAccountId STRING NOT NULL,
            qtdTotalProcessos INT64 NOT NULL,

            compradorCPF STRING NOT NULL,
            compradorNome STRING,
            compradorEmail STRING,
            compradorCelular STRING,

            pagamentoManual BOOL,
            dtPagamento TIMESTAMP NOT NULL,

            idCartosPix STRING(28) NULL,

            payerAccount STRING,
            payerAgency STRING,
            payerBankIspb STRING,
            payerClientName STRING,
            payerDescription STRING,
            payerDocument STRING,
            payerOperationNumber STRING,
            payerTxId STRING,

            dtInclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL
        )`
    },
    "bigQueryTablePixCompras": { // PIXs relacionados com as Compras
        "createTable": `CREATE TABLE {datasetId}.{tableName} (
            idCompra STRING(28) NOT NULL,
            idCampanha STRING(28) NOT NULL,
            idInfluencer STRING(28) NOT NULL,
            vlTotalCompra NUMERIC(15,2) NOT NULL,
            uidComprador STRING NOT NULL,

            pixKeyCredito STRING NOT NULL,
            pixKeyCpf STRING NOT NULL,
            pixKeyAccountId STRING NOT NULL,

            qtdTotalProcessos INT64 NOT NULL,

            pixEMV STRING NOT NULL,
            pixImagem STRING NOT NULL,
            pixAdditionalInfo STRING NOT NULL,
            pixCreatedAt TIMESTAMP NOT NULL,
            pixMerchantCity STRING NOT NULL,
            pixReceiverKey STRING NOT NULL,
            pixTxId STRING NOT NULL,
            pixValue NUMERIC(15,2) NOT NULL,

            compradorCPF STRING NOT NULL,
            compradorNome STRING,
            compradorEmail STRING,
            compradorCelular STRING,

            dtInclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL
        )`
    }

}

const getStructure = (tableType, datasetId, tableName) => {
    if (tablesStructures[tableType]) {
        const result = { ...tablesStructures[tableType] };

        result.createTable = result.createTable.replace('{datasetId}', datasetId);
        result.createTable = result.createTable.replace('{tableName}', tableName);

        result.createTable += `OPTIONS(
            labels=[("tabletype", "${_.kebabCase(tableType)}")]
        )`;

        return result;
    }

    throw new Error(`Estrutura não definida em bigqueryTables.js para ${tableType}`);
}

exports.getStructure = getStructure;
