"use strict";

// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types?hl=pt-br

const firestoreDocKeySize = 28;

// Especificação de tabelas
const tablesStructures = {
    "teste": {
        "teste": {
            schema: [
                { name: 'key1', type: 'STRING', mode: 'REQUIRED', maxLength: firestoreDocKeySize },
                { name: 'key2', type: 'STRING', mode: 'REQUIRED', maxLength: firestoreDocKeySize },
                { name: 'timestamp', type: 'TIMESTAMP', mode: 'REQUIRED' }
            ],
            primaryKey: ['key1']
        }
    }
}

const getStructure = (datasetId, tableName) => {
    if(tablesStructures[datasetId] && tablesStructures[datasetId][tableName]){
        return tablesStructures[datasetId][tableName];
    }
    throw new Error(``);
}

exports.getStructure = getStructure;