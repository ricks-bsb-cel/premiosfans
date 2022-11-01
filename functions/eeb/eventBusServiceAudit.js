"use strict";

// https://googleapis.dev/nodejs/bigquery/latest/index.html#samples

const admin = require("firebase-admin");
const { BigQuery } = require('@google-cloud/bigquery');
const bigquery = new BigQuery();
const moment = require("moment-timezone");

const location = 'southamerica-east1';
const datasetId = 'zoepay';
const auditTableName = 'eebAudit_v5';
const fullTableName = `zoepaygateway.${datasetId}.${auditTableName}`;

const schemaPayload = [
    {
        "name": "date",
        "type": "DATETIME",
        "mode": "REQUIRED"
    },
    {
        "name": "serviceId",
        "type": "STRING",
        "mode": "REQUIRED",
        "maxLength": "36"
    },
    {
        "name": "topic",
        "type": "STRING",
        "mode": "REQUIRED",
        "maxLength": "64"
    },
    {
        "name": "event",
        "type": "STRING",
        "mode": "REQUIRED",
        "maxLength": "64"
    },
    {
        "name": "messageId",
        "type": "STRING",
        "mode": "NULLABLE",
        "maxLength": "36"
    },
    {
        "name": "async",
        "type": "BOOLEAN",
        "mode": "REQUIRED"
    },
    {
        "name": "idEmpresa",
        "type": "STRING",
        "mode": "NULLABLE",
        "maxLength": "64"
    },
    {
        "name": "uid",
        "type": "STRING",
        "mode": "NULLABLE",
        "maxLength": "64"
    },
    {
        "name": "ordered",
        "type": "BOOLEAN",
        "mode": "REQUIRED"
    },
    {
        "name": "noAuth",
        "type": "BOOLEAN",
        "mode": "REQUIRED"
    },
    {
        "name": "error",
        "type": "BOOLEAN",
        "mode": "REQUIRED"
    },
    {
        "name": "orderingKey",
        "type": "STRING",
        "mode": "NULLABLE",
        "maxLength": "64"
    },
    {
        "name": "attributes",
        "type": "JSON",
        "mode": "NULLABLE"
    },
    {
        "name": "data",
        "type": "JSON",
        "mode": "NULLABLE"
    },
    {
        "name": "result",
        "type": "JSON",
        "mode": "NULLABLE"
    }
];


const auditPath = messageId => {
    const hoje = moment().tz("America/Sao_Paulo").format('YYYY-MM-DD');
    return `/eebAudit/${hoje}/${messageId}`;
}

const addAuditMessageId = (messageId, field) => {
    return new Promise((resolve, reject) => {

        // Se não houver messageId, quer dizer que a msg não veio do pubsub
        if (!messageId) { return resolve(); }

        const path = auditPath(messageId) + '/' + field;

        return admin.database().ref(path).set(
            moment().tz("America/Sao_Paulo").format('YYYY-MM-DD HH:mm:ss.SSS')
        )
            .then(_ => {
                return resolve();
            })
            .catch(e => {
                return reject(e);
            })
    })
}

const startAuditMessageId = messageId => { return addAuditMessageId(messageId, 'start'); }
const endAuditMessageId = messageId => { return addAuditMessageId(messageId, 'end'); }

const auditMessageIdExists = messageId => {
    return new Promise((resolve, reject) => {
        const path = `${auditPath()}/${messageId}/start`;

        return admin.database().ref(path).once("value")
            .then(result => {
                return resolve(Boolean(result.val()));
            })
            .catch(e => {
                return reject(e);
            })
    })
}

const savePayload = (payload, event, result) => {
    return new Promise((resolve, reject) => {

        const
            dtHoje = moment().tz("America/Sao_Paulo"),
            idEmpresa =
                (payload.data || {}).idEmpresa ||
                (payload.data.newDoc || {}).idEmpresa ||
                (payload.data.oldDoc || {}).idEmpresa ||
                'not-set',
            uid = (payload.attributes || {}).uid || 'not-set';

        const rows = [
            {
                "date": dtHoje.format('YYYY-MM-DD HH:mm:ss.SSS'),
                "serviceId": payload.serviceId || 'not-set',
                "messageId": payload.messageId || null,
                "topic": payload.topic || 'not-set',
                "idEmpresa": idEmpresa,
                "uid": uid,
                "ordered": typeof payload.ordered === 'boolean' ? payload.ordered : false,
                "noAuth": typeof payload.noAuth === 'boolean' ? payload.noAuth : false,
                "error": event.includes('error'),
                "async": typeof payload.async === 'boolean' ? payload.async : false,
                "orderingKey": payload.orderingKey || null,
                "event": event || 'not-set',
                "attributes": payload.attributes ? JSON.stringify(payload.attributes) : null,
                "data": payload.data ? JSON.stringify(payload.data) : null,
                "result": result ? JSON.stringify(result) : null
            }
        ];

        bigquery.dataset(datasetId).table(auditTableName).insert(rows)

            .then(_ => {
                return resolve(null);
            })

            .catch(e => {
                if (e.code === 404) {
                    console.info(`Creating table ${auditTableName}`);
                    createAuditTable();
                }
                return reject(new Error(e.message));
            })

    })
}

const eventMessageExists = function (event, messageId) {
    return new Promise((resolve, reject) => {
        const query = `SELECT count(*) AS qtd FROM \`${fullTableName}\` WHERE messageId='${messageId}' AND event='${event}'`;

        const options = {
            query: query,
            location: location,
        };

        bigquery.createQueryJob(options)
            .then(([job]) => {
                return job.getQueryResults();
            })
            .then(([rows]) => {
                return resolve(rows[0].qtd > 0);
            })
            .catch(e => {
                return reject(e);
            })
    })
}

const createAuditTable = _ => {
    return new Promise((resolve, reject) => {

        const options = {
            schema: schemaPayload,
            location: location
        };

        bigquery
            .dataset(datasetId)
            .createTable(auditTableName, options)
            .then(_ => {
                console.error('createAuditTable', 'Created')
                return resolve();
            })
            .catch(e => {
                console.error('createAuditTable', e)
                return reject(e);
            })

    })
}

exports.startAuditMessageId = startAuditMessageId;
exports.endAuditMessageId = endAuditMessageId;
exports.auditMessageIdExists = auditMessageIdExists;

exports.savePayload = savePayload;

exports.eventMessageExists = eventMessageExists;
