"use strict";

const { Logging } = require('@google-cloud/logging');
const projectId = 'zoepaygateway';
const logging = new Logging({ projectId });
const log = logging.log('zoepaybackend');

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

    let token =
        request.headers['x-forwarded-authorization'] ||
        request.headers['authorization'] ||
        request.headers['token'] ||
        cookies.get("__session") ||
        (request.query && request.query.token ? request.query.token : null) ||
        null;

    if (token && token.startsWith("Bearer ")) {
        token = token.substr(7);
    }

    if (!token && request.query && request.query.token) {
        token = request.query.token;
    }

    return token;
}

exports.getHost = getHost;
exports.base64ToJson = base64ToJson;
exports.logType = logType;
exports.log = writeLog;
exports.setDateTime = setDateTime;
exports.getUserTokenFromRequest = getUserTokenFromRequest;
