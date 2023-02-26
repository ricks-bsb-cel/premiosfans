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
            influencerNome STRING(512),
            influencerEmail STRING(256),
            influencerCelular STRING(32),

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
            influencerNome STRING(512),
            influencerEmail STRING(256),
            influencerCelular STRING(32),

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

            idCartosPix STRING(28),

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
            influencerNome STRING(512),
            influencerEmail STRING(256),
            influencerCelular STRING(32),

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
    },

    "bigQueryTablePremiosCompras": { // Premios das compras (depois do pagamento)
        "createTable": `CREATE TABLE {datasetId}.{tableName} (
            idTituloPremio STRING(28) NOT NULL,
            idPremio STRING(28) NOT NULL,
            idSorteio STRING(28) NOT NULL,
            idTitulo STRING(28) NOT NULL,
            idCompra STRING(28) NOT NULL,
            idCampanha STRING(28) NOT NULL,

            posPremio INT64 NOT NULL,

            uidComprador STRING NOT NULL,
            
            numeroDaSorte INT64 NOT NULL,

            premioDescricao STRING NOT NULL,
            premioValor NUMERIC(15,2) NOT NULL,

            dtSorteio DATE NOT NULL,

            dtInclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL
        )`
    },

    "bigQueryTablePixIn": { // Premios das compras (depois do pagamento)
        "createTable": `CREATE TABLE {datasetId}.{tableName} (
            accountId STRING(38) NOT NULL,
            accountAgency STRING NOT NULL,
            accountBankId STRING NOT NULL,
            accountCompanyName STRING NOT NULL,
            accountDocumentNumber STRING(14) NOT NULL,
            accountEmail STRING NOT NULL,
            accountNumber STRING NOT NULL,
            accountPersonType STRING NOT NULL,
            accountType STRING NOT NULL,

            amount NUMERIC(15,2) NOT NULL,
            category STRING NOT NULL,

            payerAccount STRING NOT NULL,
            payerAccountType STRING NOT NULL,
            payerAgency STRING,
            payerBankIspb STRING,
            payerName STRING,
            payerDocument STRING,
            
            operationNumber STRING NOT NULL,
            transactionId STRING NOT NULL,
            txId STRING,

            createdAt TIMESTAMP,
            updatedAt TIMESTAMP,

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
