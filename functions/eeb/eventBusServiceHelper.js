"use strict";

const { Logging } = require('@google-cloud/logging');
const projectId = 'premios-fans';
const logging = new Logging({ projectId });
const log = logging.log('premiosfansbackend');
const needle = require('needle');

const logType = {
    default: 'DEFAULT',
    debug: 'DEBUG',
    info: 'INFO',
    notice: 'NOTICE',
    warning: 'WARNING',
    error: 'ERROR',
    critical: 'CRITICAL',
    alert: 'ALERT',
    emergency: 'EMERGENCY'
}

const getHost = request => {
    if (!request) return null;

    let result = null;

    if (request.hostname.indexOf("cloudfunctions") >= 0) {
        result = request.headers["x-forwarded-host"];
    } else {
        result = request.hostname;
    }

    if (result) result = result.toLowerCase();

    if (result && result.substr(0, 4) === "www.") result = result.substr(4);

    return result ? result.toLowerCase() : null;
}

const base64ToJson = data => {
    const result = {};
    let messageData;

    if (!data) {
        return result;
    }

    try {
        messageData = Buffer.from(data, 'base64').toString('utf-8');
        return JSON.parse(messageData);
    } catch (e) {
        return {
            dataError: e.message,
            dataUTF8: messageData,
            dataBase64: data
        }
    }
}

function writeLog(text, type, labels) {

    const metadata = {
        resource: { type: 'global' },
        severity: type || logType.info,
        labels: {
            functionName: 'eeb'
        }
    };

    if (labels) {
        metadata.labels = Object.assign(metadata.labels, labels);
    }

    // Labels nunca pode conter nulos ou undefined
    Object.keys(labels).forEach(l => {
        if (!labels[l] || typeof labels[l] === 'undefined') { delete labels[l]; }
    })

    const entry = log.entry(metadata, text);

    log.write(entry);
}

const setDateTime = (obj, prefixo) => {
    const moment = require("moment-timezone");

    const hoje = moment().tz("America/Sao_Paulo");

    obj[(prefixo || "inclusao")] = hoje.format("YYYY-MM-DD HH:mm:ss");
    obj[(prefixo || "inclusao") + "_js"] = hoje.unix();
    obj[(prefixo || "inclusao") + "_js_desc"] = 0 - hoje.unix();
}

const getUserTokenFromRequest = (request, response) => {

    const Cookies = require("cookies");
    const cookies = new Cookies(request, response);

    let token = null;

    if (request) {
        token = request.headers['x-forwarded-authorization'] ||
            request.headers['authorization'] ||
            request.headers['token'] ||
            (request.query && request.query.token ? request.query.token : null) ||
            null;
    }

    token = token || cookies.get("__session") || null;

    if (token && token.startsWith("Bearer ")) {
        token = token.substr(7);
    }

    if (!token && request.query && request.query.token) {
        token = request.query.token || null;
    }

    return token;
}

const callNeddleGet = (endpoint, headers) => {
    return new Promise((resolve, reject) => {
        const auditHttp = require('./eventBusServiceAuditHttp');

        const audit = {
            verb: 'get',
            type: 'request',
            url: endpoint,
            headers: headers
        };

        return needle('get', endpoint, { headers: headers })
            .then(needleResult => {

                audit.result = needleResult.body;
                audit.type = 'result';

                const result = {
                    data: needleResult.body,
                    statusCode: needleResult.statusCode
                }

                if (needleResult.message && result.statusCode !== 200) {
                    result.message = needleResult.message;

                    audit.error = {
                        statusCode: result.statusCode,
                        message: needleResult.message
                    };
                }

                auditHttp.save(audit);

                return resolve(result);
            })

            .catch(e => {
                audit.type = 'error';

                audit.error = {
                    code: e.code || null,
                    message: e.message || null
                }

                auditHttp.save(audit);

                return reject(e);
            })
    })
}

const callNeddlePost = (endpoint, payload, headers) => {
    return new Promise((resolve, reject) => {
        const auditHttp = require('./eventBusServiceAuditHttp');

        const audit = {
            verb: 'post',
            type: 'request',
            url: endpoint,
            payload: payload,
            headers: headers
        };

        auditHttp.save(audit);

        return needle(
            'post',
            endpoint,
            payload,
            {
                json: true,
                headers: headers
            }
        )
            .then(needleResult => {

                const result = {
                    data: needleResult.body,
                    statusCode: needleResult.statusCode
                }

                audit.result = needleResult.body;
                audit.type = 'result';

                if (needleResult.message && result.statusCode !== 200) {
                    result.message = needleResult.message;

                    audit.error = {
                        statusCode: result.statusCode,
                        message: needleResult.message
                    };
                }

                auditHttp.save(audit);

                return resolve(result);

            })

            .catch(e => {
                audit.type = 'error';

                audit.error = {
                    code: e.code || null,
                    message: e.message || null
                }

                auditHttp.save(audit);

                return reject(e);
            })
    })
}

const callNeddleDelete = (endpoint, headers) => {
    return new Promise((resolve, reject) => {

        return needle(
            'delete',
            endpoint,
            {
                json: true,
                headers: headers
            }
        )
            .then(needleResult => {

                const result = {
                    data: needleResult.body,
                    statusCode: needleResult.statusCode
                }

                if (needleResult.message && result.statusCode !== 200) {
                    result.message = needleResult.message;
                }

                return resolve(result);

            })

            .catch(e => {
                return reject(e);
            })
    })
}

exports.getHost = getHost;
exports.base64ToJson = base64ToJson;
exports.logType = logType;
exports.log = writeLog;
exports.setDateTime = setDateTime;
exports.getUserTokenFromRequest = getUserTokenFromRequest;

exports.http = {
    get: callNeddleGet,
    post: callNeddlePost,
    delete: callNeddleDelete
}
