"use strict";

// https://googleapis.dev/nodejs/bigquery/latest/index.html#samples

const { BigQuery } = require('@google-cloud/bigquery');
const bigquery = new BigQuery();

const datasetId = 'http';
const tableName = 'calls';

/*
CREATE TABLE http.calls (
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    verb STRING NOT NULL,
    type STRING NOT NULL,
    url STRING NOT NULL,
    payload JSON,
    headers JSON,
    result JSON,
    error JSON
);
*/

const save = data => {
    return new Promise((resolve, reject) => {

        if (!data || !data.verb || !data.type || !data.url) {
            throw new Error('Invalid call for eventBusServiceAuditHttp');
        }

        let row = {
            verb: data.verb,
            type: data.type,
            url: data.url
        };

        if (data.payload && typeof data.payload === 'object') row.payload = { ...data.payload };
        if (data.headers && typeof data.headers === 'object') row.headers = { ...data.headers };
        if (data.result && typeof data.result === 'object') row.result = { ...data.result };
        if (data.error && typeof data.error === 'object') row.error = { ...data.error };

        if (row.payload) delete row.payload.password;
        if (row.headers) delete row.headers.password;
        if (row.headers) delete row.headers['x-api-key'];
        if (row.resolve) delete row.result.password;
        if (row.error) delete row.error.password;

        if (row.payload) row.payload = JSON.stringify(row.payload);
        if (row.headers) row.headers = JSON.stringify(row.headers);
        if (row.result) row.result = JSON.stringify(row.result);
        if (row.error) row.error = JSON.stringify(row.error);

        const rows = [row];

        bigquery.dataset(datasetId).table(tableName).insert(rows)

            .then(_ => {
                return resolve(null);
            })

            .catch(e => {
                console.error(e);

                return reject(e);
            })

    })
}

exports.save = save;
