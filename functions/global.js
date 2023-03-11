const { Timestamp } = require('firebase-admin/firestore');

const admin = require("firebase-admin");
const Handlebars = require("handlebars");
const functions = require("firebase-functions");
const moment = require("moment-timezone");
const randomstring = require("randomstring");
const { performance } = require('perf_hooks');
const path = require('path');
const _ = require("lodash");
const fs = require("fs");

var pStart = null;

exports.performanceStart = _ => {
    pStart = performance.now();
}

exports.performanceEnd = _ => {
    const end = performance.now();
    return end - pStart;
}

const encryptString = (value, secret) => {
    try {
        const Cryptr = require('cryptr');
        const cryptr = new Cryptr(secret);

        return cryptr.encrypt(value);
    }
    catch (e) {
        throw global.newError(e);
    }
}
exports.encryptString = encryptString;


const decryptString = (value, secret) => {
    try {
        const Cryptr = require('cryptr');
        const cryptr = new Cryptr(secret);

        return cryptr.decrypt(value);
    }
    catch (e) {
        throw global.newError(e);
    }
}
exports.decryptString = decryptString;


const newError = (msg, code, details) => {
    const e = new Error(msg);
    if (code) { e.code = code; }
    if (details) { e.details = details; }
    return e;
}
exports.newError = newError;

exports.randomNumber = max => {
    return _.random(max);
}

exports.shuffleArray = array => {
    return _.shuffle(array);
}

const splitReplace = function (value, search, replacement) {
    return value.split(search).join(replacement);
}

const formatMoney = (value, showMoeda, html) => {
    const locale = Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BLR' });
    const moeda = showMoeda ? (html ? '<small class="currency">R$</small>' : 'R$') : '';
    let result = locale.format(value);

    result = result.replace('BLR', moeda);

    if (html) {
        const centavos = result.slice(result.length - 3);
        result = result.replace(centavos, `<small class="cents">${centavos}</small>`);
    }

    return result;
}
exports.formatMoney = formatMoney;

exports.responseError = (response, e) => {

    let
        errorCode = 500,
        errorMessage = 'Server error'

    if (typeof e === 'object' && e.constructor.name === 'FirebaseAuthError') {
        errorCode = 401;
        errorMessage = 'Token has expired';
    } else if (e && e.code) {
        errorCode = e.code;
        errorMessage = e.message || null;
    } else {
        errorCode = 500;
        errorMessage = e.message || null;
    }

    return response.status(errorCode).json(
        defaultResult({
            code: errorCode,
            error: errorMessage
        })
    );
}


exports.verifyTokenFromRequest = request => {

    return new Promise((resolve, reject) => {

        const host = _.kebabCase(getHost(request) || null),
            isGatewayCall = typeof request.headers['x-request-id'] !== 'undefined';

        let apiConfig,
            token = request.headers['x-forwarded-authorization'] ||
                request.headers['authorization'] ||
                request.headers['token'] ||
                null;

        if (!token) {
            return reject(new Error('Token not found on request...'));
        }

        if (token && token.startsWith("Bearer ")) {
            token = token.substr(7);
        }

        if (token.length < 128) {
            return admin.database().ref("/apiConfig/" + token).once("value")

                .then(apiConfig => {

                    if (!apiConfig.exists()) {
                        throw new Error('invalid token');
                    }

                    apiConfig = apiConfig.val();

                    if (!apiConfig.ativo) {
                        throw new Error('token disavowed');
                    }

                    if (apiConfig.gatewayOnly && !isGatewayCall) {
                        throw new Error('invalid call (gateway only)');
                    }

                    return saveHosts(apiConfig, token, host);
                })

                .then(data => {
                    apiConfig = data;

                    if (!apiConfig.hosts[host]) {
                        throw new Error(`host prohibited: ${host}`);
                    }

                    return resolve(apiConfig)
                })

                .catch(e => {
                    return reject(e);
                })

        } else {

            return admin.auth().verifyIdToken(token)

                .then(user => {
                    return resolve(user);
                })

                .catch(e => {
                    return reject(e);
                })
        }

    })
}


const saveHosts = (apiConfig, token, host) => {
    return new Promise((resolve, reject) => {

        apiConfig.hosts = apiConfig.hosts || {};

        host = _.kebabCase(host);

        if (typeof apiConfig.hosts[host] === 'undefined') {
            apiConfig.hosts[host] = false;
            return admin.database().ref(`/apiConfig/${token}/hosts/${host}`).set(false)
                .then(_ => {
                    return resolve(apiConfig);
                })
                .catch(e => {
                    return reject(e);
                })
        } else {
            return resolve(apiConfig);
        }

    })
}


exports.getUserTokenFromRequest = (request, response) => {

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


const defaultResult = (parm, ignoreIdEmpresa) => {

    try {
        ignoreIdEmpresa = typeof ignoreIdEmpresa === 'boolean' ? ignoreIdEmpresa : false;

        if (parm.error) { ignoreIdEmpresa = true; }

        const dtHoje = Timestamp.now();

        let result = {};

        if (parm.id) { result.id = parm.id; }
        if (parm.cpf) { result.cpf = parm.cpf; }
        if (parm.idUser) { result.idUser = parm.idUser; }
        if (parm.message) { result.message = parm.message; }
        if (parm.details) { result.details = parm.details; }

        if (parm.doc) {
            if (Array.isArray(parm.doc)) {
                throw new Error('Doc não pode ser uma array. User rows.');
            }
            result.doc = parm.doc;
        }

        if (parm.data) {

            if (Array.isArray(parm.data)) {
                parm.rows = parm.data;
                delete parm.data;
            }

            result.data = parm.data;

            if (!result.id && result.data && result.data.id) {
                result.id = result.data.id;
            }

        }

        if (parm.rows) {

            if (!Array.isArray(parm.rows)) {
                throw new Error('Rows tem que ser uma array');
            }

            result.rowcount = parm.rows.length
            result.rows = parm.rows;
        }

        if ((parm.extrainfo || parm.extraInfo)) {
            result.extraInfo = parm.extrainfo || parm.extraInfo;
        }

        if (result.extraInfo && !Object.keys(result.extraInfo).length) {
            delete result.extraInfo;
        }

        if (parm.extend) {
            result.extend = result.extend || {}
            result.extend = Object.assign(result.extend, parm.extend);
        }

        if (parm.actions && parm.actions.length) {
            result.actions = parm.actions;
        }

        if (parm.error) {

            if (typeof parm.error === 'object' && parm.error.constructor.name === 'Error') {
                result.error = parm.error.message;
            } else if (typeof parm.error === 'object' && Array.isArray(parm.error)) {
                result.error = '';
                parm.error.forEach(e => {
                    result.error += (e + '; ');
                })
            } else {
                result.error = parm.error;
            }
        }

        result = Object.assign(result, {
            datetimeserver: moment(dtHoje.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS'),
            code: (!parm.code && parm.error ? 500 : parm.code || 200),
            versionId: getVersionId()
        })

        return result;
    }
    catch (e) {
        console.error(e);
        throw e;
    }
}


exports.defaultResult = defaultResult;


/*
exports.currentIp = request => {
    let ips = request.headers['x-forwarded-for'] || request.connection.remoteAddress || request.socket.remoteAddress || (request.connection.socket ? request.connection.socket.remoteAddress : null);
    return ips.split(",")[0];
}
*/


exports.toBase64 = value => {
    const result = Buffer.from(value).toString('base64');
    return result.replaceAll('/', '~');
}


exports.fromBase64 = value => {
    const atob = require('atob');
    return atob(value.replaceAll('~', '/'));
}


exports.getFrontRoutes = (version, fileVersion) => {

    const f7Routes = require('./frontRoutes.json'),
        result = [];

    f7Routes.forEach(route => {
        const f = route;

        if (f.componentUrl) {
            f.componentUrl = f.componentUrl.replace('{{fileVersion}}', fileVersion);
        }

        if (f.popup && f.popup.componentUrl) {
            f.popup.componentUrl = f.popup.componentUrl.replace('{{fileVersion}}', fileVersion);
        }

        if (f.sheet && f.sheet.componentUrl) {
            f.sheet.componentUrl = f.sheet.componentUrl.replace('{{fileVersion}}', fileVersion);
        }

        f.version = version;

        result.push(f);
    })

    return result;
}

const toBoolean = value => { return typeof value === 'boolean' ? value : value === 'true'; }
exports.toBoolean = value => { return toBoolean(value); }
exports.toBool = value => { return toBoolean(value); }


exports.toFixed = (value, dec) => {
    return parseFloat(parseFloat(value).toFixed(dec || 2));
}

/*
exports.capitalize = (str, lower) => {
    if (typeof lower === 'undefined') {
        lower = true
    }
    str = str || '';
    return (lower ? str.toLowerCase() : str).replace(/(?:^|\s|["'([{])+\S/g, match => match.toUpperCase());
};
*/

const capitalize = value => {
    if (!value) { return null; }
    const artigos = ['o', 'os', 'a', 'as', 'um', 'uns', 'uma', 'umas', 'a', 'ao', 'aos', 'à', 'às', 'de', 'do', 'dos', 'da', 'das', 'dum', 'duns', 'duma', 'dumas', 'em', 'no', 'nos', 'na', 'nas', 'num', 'nuns', 'numa', 'numas'];
    let result = '';
    value.split(' ').forEach(word => {
        word = word.trim().toLowerCase();
        result += (artigos.includes(word) ? word : word.charAt(0).toUpperCase() + word.slice(1)) + ' ';
    })
    return result.trimEnd();
}
exports.capitalize = capitalize;


exports.randomVersion = () => { return randomVersion(); }
const randomVersion = () => { return randomstring.generate(7); }


const generateRandomId = size => {
    if (!size) size = 36;
    return randomstring.generate(size);
}


exports.generateRandomId = size => {
    return generateRandomId(size);
}


exports.tryParseInt = (v, d) => {

    if (!v) { return d; }

    let result;

    try {
        result = parseInt(v);
        return result;
    }

    catch (e) {
        return d;
    }
}


const generatePassword = (attr) => {
    let parms = {
        length: 7,
        capitalization: "lowercase",
        readable: true
    };
    parms = Object.assign(parms, attr || {});
    return randomstring.generate(parms);
}
exports.generatePassword = generatePassword;


exports.getVersionId = () => { return getVersionId(); }
const getVersionId = () => {
    let version = 'desenv-' + randomVersion();

    if (functions.config().version) {
        version = functions.config().version.id;
    }

    return version;
}


const firstName = name => {
    if (!name) { return null; }
    const pos = name.indexOf(' ');
    if (pos < 0) { return name; }
    return name.substr(0, pos);
}

exports.firstName = name => { return firstName(name); }

exports.primeiroNome = name => { return firstName(name); }

const logInfo = (v1, v2, v3) => {
    // O LogInfo não lanca mensagens no log em produção
    if (!functions.config().version) {
        const logLineDetails = ((new Error().stack).split("at ")[2]).trim();
        if (v1 && v2 && v3) {
            console.error("\r\n>>> info ~ ", v1, v2, v3, "\r\nfrom", logLineDetails, "\r\n");
        } else if (v1 && v2) {
            console.error("\r\n>>> info ~ ", v1, v2, "\r\nfrom", logLineDetails, "\r\n");
        } else if (v1) {
            console.error("\r\n>>> info ~ ", v1, "\r\nfrom", logLineDetails, "\r\n");
        } else {
            console.error("\r\n>>> info ~ ", "\r\nfrom", logLineDetails, "\r\n");
        }
    }
}

exports.logInfo = logInfo;


const hash = value => {
    const crypto = require("crypto");
    return crypto.createHash("md5").update(value).digest("hex");
}

exports.hash = hash;

exports.booleanOrString = value => {
    if (value && typeof value === 'string' && value.toLowerCase() === 'true') { value = true; }
    if (value && typeof value === 'string' && value.toLowerCase() === 'false') { value = false; }
    return value;
}

exports.shuffle = word => { return shuffle(word); }
const shuffle = word => {
    let shuffledWord = "";
    word = word.split("");
    while (word.length > 0) {
        shuffledWord += word.splice(word.length * Math.random() << 0, 1);
    }
    return shuffledWord;
}


exports.getVersionDate = () => { return getVersionDate(); }
const getVersionDate = () => {
    let vDate = "localhost";
    if (functions.config().version) vDate = functions.config().version.date;
    return vDate;
}


exports.getContentTypeByExtension = pathFile => {
    let result = null;

    const path = require("path");
    const fileName = path.basename(pathFile)
    const extension = path.extname(fileName);

    switch (extension) {
        case '.ico':
            result = "image/x-icon";
            break;

        case '.png':
            result = "image/png";
            break;

        case '.svg':
            result = "image/svg+xml";
            break;

        case '.jpg':
            result = "image/jpeg";
            break;

        case '.js':
            result = "application/javascript; charset=utf-8";
            break;

        case '.html':
            result = "text/html; charset=utf-8";
            break;

        case '.css':
            result = "text/css; charset=utf-8";
            break;

        default:
            result = null;

    }

    return result;
}


exports.currentIp = request => {
    const ips = request.headers['x-forwarded-for'] || request.connection.remoteAddress || request.socket.remoteAddress || (request.connection.socket ? request.connection.socket.remoteAddress : null);
    return (ips ? ips.split(",")[0] : null);
}


exports.toDate = (unixValue, format) => {
    if (!unixValue) { return null; }
    const d = moment(unixValue).tz("America/Sao_Paulo");
    return d.format(format || "DD/MM/YYYY HH:mm");
}


exports.asDate = (value) => {
    if (!value) { return null; }
    if (value.constructor.name === 'Timestamp') {
        value = value.toDate();
    }
    const d = moment(value).tz("America/Sao_Paulo");
    return d.format("YYYY-MM-DD HH:mm:ss");
}


exports.setDateTime = (obj, prefixo, addValue, addType) => {
    const hoje = moment().tz("America/Sao_Paulo");

    if (addValue) {
        hoje.add(addValue, addType || 'minutes');
    }

    obj[(prefixo || "inclusao")] = hoje.format("YYYY-MM-DD HH:mm:ss");

    obj[(prefixo || "inclusao") + "_js"] = hoje.unix();
    obj[(prefixo || "inclusao") + "_js_desc"] = 0 - hoje.unix();
    obj[(prefixo || "inclusao") + "_timestamp"] = Timestamp.fromDate(hoje.toDate());
}

// End of Time...
exports.setEndOfTime = (obj, prefixo) => {
    const m = moment({ year: 2222, month: 5, day: 29, hour: 18, minute: 15, second: 15 }).tz("America/Sao_Paulo");

    obj[prefixo] = m.format("YYYY-MM-DD HH:mm:ss");

    obj[prefixo + '_js'] = m.unix();
    obj[prefixo + '_js_desc'] = 0 - m.unix();
    obj[prefixo + '_timestamp'] = Timestamp.fromDate(m.toDate());
}


const isValidDate = unixDate => {
    // YYYY-MM-DD
    const pattern = /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/g;
    if (!unixDate || !pattern.test(unixDate)) {
        return false;
    }

    const momentDate = moment(unixDate, 'YYYY-MM-DD'); // .tz("America/Sao_Paulo");
    momentDate.hour(0).minute(0).second(0).millisecond(0);

    return momentDate.isValid() && momentDate.format("YYYY-MM-DD") === unixDate;
}
exports.isValidDate = isValidDate;


const todayMoment = _ => {
    const result = moment();
    result.hour(0).minute(0).second(0).millisecond(0);
    return result;
}
exports.todayMoment = todayMoment;


const dateToMoment = (value, br) => {
    let result;

    br = typeof br === 'boolean' ? br : false;

    if (br) {
        result = moment(value, 'YYYY-MM-DD').tz("America/Sao_Paulo");
        result.add('day', 1);
    } else {
        result = moment(value, 'YYYY-MM-DD');
    }

    result.hour(0).minute(0).second(0).millisecond(0);

    return result;
}


exports.isValidDtNascimento = (unixValue, idadeMinima, idadeMaxima) => {

    if (!isValidDate(unixValue)) {
        return false;
    }

    const momentDate = dateToMoment(unixValue);
    const hoje = todayMoment();

    return hoje.isAfter(momentDate) &&
        (hoje.year() - momentDate.year()) > (idadeMinima || 15) &&
        (hoje.year() - momentDate.year()) < (idadeMaxima || 120);
}


exports.asTimestampData = (unixValue, br) => {
    br = typeof br === 'boolean' ? br : false;

    if (!isValidDate(unixValue)) {
        throw new Error(`Invalid date format [${unixValue}]`);
    }

    const momentDate = dateToMoment(unixValue, br);

    return Timestamp.fromDate(momentDate.toDate());
}


const getDtHoje = (prefixo) => {
    const result = {};
    const hoje = moment().tz("America/Sao_Paulo");
    result[prefixo + "_js"] = hoje.unix();
    result[prefixo + "_js_desc"] = 0 - hoje.unix();
    return result;
}


exports.getToday = format => {
    const hoje = moment().tz("America/Sao_Paulo");
    return hoje.format(format || "YYYY-MM-DD HH:mm:ss");
}


/**
 * @name setDtHoje
 * @description Adiciona a data de hoje a um objeto
 * @param {objeto} obj o objeto a que se deseja adicionar a data de hoje
 * @param {string} prefixo prefixo desejado para adicionar a data de hoje. Padrão dtInclusao.
 */
exports.setDtHoje = (obj, prefixo = null) => {
    if (!prefixo) prefixo = "dtInclusao";
    obj = Object.assign(obj, getDtHoje(prefixo));
}


/**
 * @name getDtHoje
 * @description Retorna um objeto com a data de hoje jsj, ymd e dmy
 * @param {string} prefixo prefixo desejado para adicionar a data de hoje. Padrão dtInclusao.
 */
exports.getDtHoje = prefixo => { return getDtHoje(prefixo); }


exports.resultError = error => {
    console.error(error);
    return {
        "success": false,
        "error": error,
        "code": 500,
        "version": getVersionId()
    };
}


exports.resultSuccess = (msg, data) => {
    return {
        "success": true,
        "msg": msg || "Success",
        "code": 200,
        "data": data || null,
        "version": getVersionId()
    };
}


exports.arrayLength = obj => {
    if (!obj || !Array.isArray(obj)) return 0;
    return obj.length;
}


/* Verifica se um objeto é uma array de strings ou nulo */
exports.isStringArray = obj => {
    if (!obj) return true;
    if (!Array.isArray(obj)) return false;
    let errors = 0;
    obj.forEach(w => { if (typeof w !== "string") errors++; })
    if (errors > 0) return false;
    return true;
}


exports.isString = value => {
    return typeof value === 'string' || value instanceof String;
}


exports.isBoolean = value => {
    return typeof value === "boolean";
}


exports.compile = (txt, obj) => {
    txt = txt.toString();
    const template = Handlebars.compile(txt);
    return template(obj);
}


exports.imgUrlToWebp = imgUrl => {
    const dot = imgUrl.lastIndexOf(".");
    return imgUrl.substr(0, dot) + ".webp";
}


exports.imgUrlToJpeg = imgUrl => {
    const dot = imgUrl.lastIndexOf(".");
    return imgUrl.substr(0, dot) + ".jpeg";
}


/**
 * Base 10to36 e 36to10
 */
const charMap = "7hkcpiwmn5xua8srjeoy6g1lb39z4q2t0dvf";
const base10to36 = value => {
    if (!value || !_.isNumber(value)) return null;
    let result = "";
    // eslint-disable-next-line no-constant-condition
    while (true) {
        if (value < charMap.length) {
            result = charMap.substr(value, 1) + result;
            break;
        }
        result = charMap.substr(value % charMap.length, 1) + result;
        value = Math.trunc(value / charMap.length);
    }
    return result;
}
const base36to10 = value => {
    if (!value) return null;
    value = String(value);
    let base = 0;
    let result = 0;
    let char = null;
    while (value) {
        char = value.slice(-1);
        value = value.substr(0, value.length - 1);
        result += charMap.indexOf(char) * Math.pow(charMap.length, base);
        base++;
    }
    return result;
}
exports.convert = {
    "base10to36": v => { return base10to36(v); },
    "base36to10": v => { return base36to10(v); }
}


/**
 * Retorna apenas os números de uma string
 */
const numbersOnly = value => { if (!value) return null; return value.replace(/\D/g, ""); }
exports.numbersOnly = numbersOnly;


const hideEmail = value => {
    if (!value || value.indexOf("@") < 0) return null;
    const parts = value.split("@");
    return parts[0].substr(0, 1) + "*".repeat(parts[0].length - 2) + parts[0].substr(parts[0].length - 1) + "@" + parts[1];
}
exports.hideEmail = hideEmail;


const hideCelular = celular => {
    celular = this.getFormatPhoneNumber(celular);
    return celular.substr(0, 8) + '***-**' + celular.substr(14, 2);
}
exports.hideCelular = hideCelular;


const hideCpf = cpf => {
    cpf = cpf || null;
    if (!cpf) { return null; }
    cpf = formatCpf(cpf);
    if (!cpf) { return null; }
    return cpf.substr(0, 2) + '*.***.***-' + cpf.substr(12, 2);
}
exports.hideCpf = hideCpf;


/**
 * Verifica se a string é compatível com email
 */
const emailIsValid = email => {
    if (!email) return true;
    const expression = /(?!.*\.{2})^([a-z\d!#$%&'*+\-\/=?^_`{|}~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]+(\.[a-z\d!#$%&'*+\-\/=?^_`{|}~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]+)*|"((([ \t]*\r\n)?[ \t]+)?([\x01-\x08\x0b\x0c\x0e-\x1f\x7f\x21\x23-\x5b\x5d-\x7e\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|\\[\x01-\x09\x0b\x0c\x0d-\x7f\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))*(([ \t]*\r\n)?[ \t]+)?")@(([a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|[a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF][a-z\d\-._~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]*[a-z\d\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])\.)+([a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]|[a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF][a-z\d\-._~\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]*[a-z\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])\.?$/i;
    return expression.test(String(email).toLowerCase())
}
exports.emailIsValid = emailIsValid;


exports.urlIsValid = url => {
    const r = new RegExp(/^(ftp|http|https):\/\/[^ "]+$/);
    return r.test(url);
}

/**
 * Verificas e o número tem formato de celular
 */
const isMobileNumber = value => {
    value = numbersOnly(value);
    if (!value) {
        return false;
    } else {
        return value.length === 11;
    }
}
exports.isMobileNumber = value => { return isMobileNumber(value); }

/**
 * Formatador de número de telefone
 */
const formatPhoneNumber = (value, ddd) => {

    const result = { "success": true, "original": null, "number": null, "formated": null };
    if (!value) return result;

    if (value.substr(0, 1) === "+") value = value.substr(3);

    value = numbersOnly(value);

    if (!value) return result;

    result.celular = value;

    if (!ddd) ddd = "61";

    switch (value.length) {
        case 13:
            result.celularFormated = "(" + value.substr(2, 2) + ") " + value.substr(4, 1) + " " + value.substr(5, 4) + "-" + value.substr(9, 4);
            break;
        case 12:
            result.celularFormated = "(" + value.substr(2, 2) + ") 9 " + value.substr(4, 4) + "-" + value.substr(8, 4);
            break;
        case 11:
            result.celularFormated = "(" + value.substr(0, 2) + ") " + value.substr(2, 1) + " " + value.substr(3, 4) + "-" + value.substr(7, 4);
            break;
        case 10:
            result.celularFormated = "(" + value.substr(0, 2) + ") 9 " + value.substr(2, 4) + "-" + value.substr(6, 4);
            break;
        case 9:
            result.celularFormated = "(" + ddd + ") " + value.substr(0, 1) + " " + value.substr(1, 4) + "-" + value.substr(5, 4);
            break;
        case 8:
            result.celularFormated = "(" + ddd + ") " + (parseInt(value.substr(0, 1)) >= 8 ? "9 " : "") + value.substr(0, 4) + "-" + value.substr(4, 4);
            break;
        default:
            result.success = false;
            break;
    }

    result.phoneNumber_int = '55' + result.celular;
    result.phoneNumber_intplus = '+55' + result.celular;

    return result;
}

exports.formatPhoneNumber = formatPhoneNumber;

exports.getFormatPhoneNumber = (value, ddd) => {
    const format = formatPhoneNumber(value, ddd);
    return format.success ? format.formated || format.celularFormated : null;
}


const createEmailFromPhone = (phone, domain) => {
    const phoneFormatted = formatPhoneNumber(phone).celularFormated;
    return '55' + numbersOnly(phoneFormatted) + '@' + domain;
}

exports.createEmailFromPhone = (phone, domain) => { return createEmailFromPhone(phone, domain); }


const createEmailFromCPFPhone = (cpf, phone, domain) => {
    const phoneFormatted = formatPhoneNumber(phone).celularFormated;
    return cpf + '-' + '55' + numbersOnly(phoneFormatted) + '@' + domain;
}
exports.createEmailFromCPFPhone = (cpf, phone, domain) => {
    return createEmailFromCPFPhone(cpf, phone, domain);
}


const formatCpf = cpf => {

    if (cpf === null) { return null; }

    if (typeof cpf !== 'string') {
        throw newError(`O cpf informado em formatCpf não é do tipo string: [${JSON.stringify(cpf)}]`);
    }

    cpf = numbersOnly(cpf);

    if (cpf.length !== 11) {
        return null;
    } else {
        return cpf.substr(0, 3) + '.' +
            cpf.substr(3, 3) + '.' +
            cpf.substr(6, 3) + '-' +
            cpf.substr(9, 2);
    }
}
exports.formatCpf = formatCpf;

const formatCnpj = cnpj => {
    if (cnpj === null) { return null; }

    cnpj = numbersOnly(cnpj);

    if (cnpj.length !== 14) {
        return null;
    } else {
        return cnpj.substr(0, 2) + '.' +
            cnpj.substr(2, 3) + '.' +
            cnpj.substr(5, 3) + '/' +
            cnpj.substr(8, 4) + '-' +
            cnpj.substr(12, 2);
    }
}

exports.formatCnpj = formatCnpj;

exports.formatCpfCnpj = cpfCnpj => {
    cpfCnpj = cpfCnpj.onlyNumbers();

    if (cpfCnpj.length === 11) {
        return formatCpf(cpfCnpj);
    } else if (cpfCnpj.length === 14) {
        return formatCnpj(cpfCnpj);
    } else {
        return null;
    }
}


const formatCep = cep => {
    if (!cep) { return null; }
    cep = cep.onlyNumbers();
    if (cep.length !== 8) { return cep; }
    return `${cep.substr(0, 2)} ${cep.substr(2, 3)}-${cep.substr(5, 3)}`
}

exports.formatCep = formatCep;

/**
 * Adiciona meses à uma data
 */
exports.addMonths = (data, meses, lastDay = false) => {
    if (!data) data = moment().tz("America/Sao_Paulo").format("YYYY-MM-DD");
    let momentDate = moment(data, "YYYY-MM-DD").tz("America/Sao_Paulo");
    if (!momentDate.isValid()) return null;
    momentDate = momentDate.add(lastDay ? meses + 1 : meses, "months");
    if (lastDay) momentDate = moment(momentDate.format("YYYY-MM-DD").substr(0, 8) + "01", "YYYY-MM-DD").subtract(1, 'days');
    return momentDate.format("YYYY-MM-DD");
}


exports.promisseRandonValue = function (min, max) {
    return new Promise(resolve => {
        if (!min || !max) {
            throw new Error('promisseRandonValue invalid range...');
        }
        setTimeout(() => {
            return resolve();
        }, Math.floor(Math.random() * (max - min) + min));
    })
}


/**
 * Registra todos os arquivos de um diretório no Handlebars
 */
exports.mapHandlebarDir = (dir, prefix) => {
    fs.readdir(dir, { withFileTypes: false }, (e, items) => {
        if (e) {
            console.error(e);
        } else if (!items) {
            console.error("Nenhum arquivo encontrado:", dir);
        } else {
            items.forEach(i => {
                if (i.indexOf(".hbs") > 0) {
                    const name = (prefix ? prefix + "-" : "") + "partial-" + i.split(".")[0];
                    const file = dir + "/" + i;
                    Handlebars.registerPartial(name, fs.readFileSync(file, "utf8"));
                }
            })
        }
    });
}


/**
 * @name renderText
 * @param  {string} text Texto a ser tratado
 * @param  {object} data dados a serem compilados
 * @returns {string}
 */
exports.renderText = (text, data) => {
    const Handlebars = require("handlebars");
    const hbText = Handlebars.compile(text);
    return hbText(data);
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

exports.getHost = getHost;

exports.localConsole = {
    info: function (request, msg) {
        if (getHost(request) === 'localhost') {
            console.info(msg);
        }
    }
}


/**
 * Transforma uma string em url
 */
exports.url = value => {
    return value ? _.kebabCase(value.trim()) : null;
}


/**
 * Retorna uma posição aleatória de uma array
 */
exports.randomItem = value => {
    if (!_.isArray(value)) return null;
    if (value.length === 1) return value[0];

    value = _.shuffle(value);

    return value[0];
}


/**
 * Busca um template HTML e o compila
 */
exports.getTemplate = (file, obj) => {
    const Handlebars = require("handlebars");
    const fs = require("fs");
    const pathFile = path.join(__dirname, "/../public", file);
    try {
        const source = fs.readFileSync(pathFile, "utf8");
        const template = Handlebars.compile(source);
        return template(obj);
    } catch (error) {
        console.log("getTemplate:", error);
        return null;
    }
}


exports.isUrl = value => {
    try {
        new URL(value);
    } catch (e) {
        return false;
    }
    return true;
}


exports.leftZeros = (number, width) => {
    width -= number.toString().length;
    if (width > 0) {
        return new Array(width + (/\./.test(number) ? 2 : 1)).join('0') + number;
    }
    return String(number);
}

const defaultDiacriticsRemovalMap = [
    { 'base': 'A', 'letters': /[\u0041\u24B6\uFF21\u00C0\u00C1\u00C2\u1EA6\u1EA4\u1EAA\u1EA8\u00C3\u0100\u0102\u1EB0\u1EAE\u1EB4\u1EB2\u0226\u01E0\u00C4\u01DE\u1EA2\u00C5\u01FA\u01CD\u0200\u0202\u1EA0\u1EAC\u1EB6\u1E00\u0104\u023A\u2C6F]/g },
    { 'base': 'AA', 'letters': /[\uA732]/g },
    { 'base': 'AE', 'letters': /[\u00C6\u01FC\u01E2]/g },
    { 'base': 'AO', 'letters': /[\uA734]/g },
    { 'base': 'AU', 'letters': /[\uA736]/g },
    { 'base': 'AV', 'letters': /[\uA738\uA73A]/g },
    { 'base': 'AY', 'letters': /[\uA73C]/g },
    { 'base': 'B', 'letters': /[\u0042\u24B7\uFF22\u1E02\u1E04\u1E06\u0243\u0182\u0181]/g },
    { 'base': 'C', 'letters': /[\u0043\u24B8\uFF23\u0106\u0108\u010A\u010C\u00C7\u1E08\u0187\u023B\uA73E]/g },
    { 'base': 'D', 'letters': /[\u0044\u24B9\uFF24\u1E0A\u010E\u1E0C\u1E10\u1E12\u1E0E\u0110\u018B\u018A\u0189\uA779]/g },
    { 'base': 'DZ', 'letters': /[\u01F1\u01C4]/g },
    { 'base': 'Dz', 'letters': /[\u01F2\u01C5]/g },
    { 'base': 'E', 'letters': /[\u0045\u24BA\uFF25\u00C8\u00C9\u00CA\u1EC0\u1EBE\u1EC4\u1EC2\u1EBC\u0112\u1E14\u1E16\u0114\u0116\u00CB\u1EBA\u011A\u0204\u0206\u1EB8\u1EC6\u0228\u1E1C\u0118\u1E18\u1E1A\u0190\u018E]/g },
    { 'base': 'F', 'letters': /[\u0046\u24BB\uFF26\u1E1E\u0191\uA77B]/g },
    { 'base': 'G', 'letters': /[\u0047\u24BC\uFF27\u01F4\u011C\u1E20\u011E\u0120\u01E6\u0122\u01E4\u0193\uA7A0\uA77D\uA77E]/g },
    { 'base': 'H', 'letters': /[\u0048\u24BD\uFF28\u0124\u1E22\u1E26\u021E\u1E24\u1E28\u1E2A\u0126\u2C67\u2C75\uA78D]/g },
    { 'base': 'I', 'letters': /[\u0049\u24BE\uFF29\u00CC\u00CD\u00CE\u0128\u012A\u012C\u0130\u00CF\u1E2E\u1EC8\u01CF\u0208\u020A\u1ECA\u012E\u1E2C\u0197]/g },
    { 'base': 'J', 'letters': /[\u004A\u24BF\uFF2A\u0134\u0248]/g },
    { 'base': 'K', 'letters': /[\u004B\u24C0\uFF2B\u1E30\u01E8\u1E32\u0136\u1E34\u0198\u2C69\uA740\uA742\uA744\uA7A2]/g },
    { 'base': 'L', 'letters': /[\u004C\u24C1\uFF2C\u013F\u0139\u013D\u1E36\u1E38\u013B\u1E3C\u1E3A\u0141\u023D\u2C62\u2C60\uA748\uA746\uA780]/g },
    { 'base': 'LJ', 'letters': /[\u01C7]/g },
    { 'base': 'Lj', 'letters': /[\u01C8]/g },
    { 'base': 'M', 'letters': /[\u004D\u24C2\uFF2D\u1E3E\u1E40\u1E42\u2C6E\u019C]/g },
    { 'base': 'N', 'letters': /[\u004E\u24C3\uFF2E\u01F8\u0143\u00D1\u1E44\u0147\u1E46\u0145\u1E4A\u1E48\u0220\u019D\uA790\uA7A4]/g },
    { 'base': 'NJ', 'letters': /[\u01CA]/g },
    { 'base': 'Nj', 'letters': /[\u01CB]/g },
    { 'base': 'O', 'letters': /[\u004F\u24C4\uFF2F\u00D2\u00D3\u00D4\u1ED2\u1ED0\u1ED6\u1ED4\u00D5\u1E4C\u022C\u1E4E\u014C\u1E50\u1E52\u014E\u022E\u0230\u00D6\u022A\u1ECE\u0150\u01D1\u020C\u020E\u01A0\u1EDC\u1EDA\u1EE0\u1EDE\u1EE2\u1ECC\u1ED8\u01EA\u01EC\u00D8\u01FE\u0186\u019F\uA74A\uA74C]/g },
    { 'base': 'OI', 'letters': /[\u01A2]/g },
    { 'base': 'OO', 'letters': /[\uA74E]/g },
    { 'base': 'OU', 'letters': /[\u0222]/g },
    { 'base': 'P', 'letters': /[\u0050\u24C5\uFF30\u1E54\u1E56\u01A4\u2C63\uA750\uA752\uA754]/g },
    { 'base': 'Q', 'letters': /[\u0051\u24C6\uFF31\uA756\uA758\u024A]/g },
    { 'base': 'R', 'letters': /[\u0052\u24C7\uFF32\u0154\u1E58\u0158\u0210\u0212\u1E5A\u1E5C\u0156\u1E5E\u024C\u2C64\uA75A\uA7A6\uA782]/g },
    { 'base': 'S', 'letters': /[\u0053\u24C8\uFF33\u1E9E\u015A\u1E64\u015C\u1E60\u0160\u1E66\u1E62\u1E68\u0218\u015E\u2C7E\uA7A8\uA784]/g },
    { 'base': 'T', 'letters': /[\u0054\u24C9\uFF34\u1E6A\u0164\u1E6C\u021A\u0162\u1E70\u1E6E\u0166\u01AC\u01AE\u023E\uA786]/g },
    { 'base': 'TZ', 'letters': /[\uA728]/g },
    { 'base': 'U', 'letters': /[\u0055\u24CA\uFF35\u00D9\u00DA\u00DB\u0168\u1E78\u016A\u1E7A\u016C\u00DC\u01DB\u01D7\u01D5\u01D9\u1EE6\u016E\u0170\u01D3\u0214\u0216\u01AF\u1EEA\u1EE8\u1EEE\u1EEC\u1EF0\u1EE4\u1E72\u0172\u1E76\u1E74\u0244]/g },
    { 'base': 'V', 'letters': /[\u0056\u24CB\uFF36\u1E7C\u1E7E\u01B2\uA75E\u0245]/g },
    { 'base': 'VY', 'letters': /[\uA760]/g },
    { 'base': 'W', 'letters': /[\u0057\u24CC\uFF37\u1E80\u1E82\u0174\u1E86\u1E84\u1E88\u2C72]/g },
    { 'base': 'X', 'letters': /[\u0058\u24CD\uFF38\u1E8A\u1E8C]/g },
    { 'base': 'Y', 'letters': /[\u0059\u24CE\uFF39\u1EF2\u00DD\u0176\u1EF8\u0232\u1E8E\u0178\u1EF6\u1EF4\u01B3\u024E\u1EFE]/g },
    { 'base': 'Z', 'letters': /[\u005A\u24CF\uFF3A\u0179\u1E90\u017B\u017D\u1E92\u1E94\u01B5\u0224\u2C7F\u2C6B\uA762]/g },
    { 'base': 'a', 'letters': /[\u0061\u24D0\uFF41\u1E9A\u00E0\u00E1\u00E2\u1EA7\u1EA5\u1EAB\u1EA9\u00E3\u0101\u0103\u1EB1\u1EAF\u1EB5\u1EB3\u0227\u01E1\u00E4\u01DF\u1EA3\u00E5\u01FB\u01CE\u0201\u0203\u1EA1\u1EAD\u1EB7\u1E01\u0105\u2C65\u0250]/g },
    { 'base': 'aa', 'letters': /[\uA733]/g },
    { 'base': 'ae', 'letters': /[\u00E6\u01FD\u01E3]/g },
    { 'base': 'ao', 'letters': /[\uA735]/g },
    { 'base': 'au', 'letters': /[\uA737]/g },
    { 'base': 'av', 'letters': /[\uA739\uA73B]/g },
    { 'base': 'ay', 'letters': /[\uA73D]/g },
    { 'base': 'b', 'letters': /[\u0062\u24D1\uFF42\u1E03\u1E05\u1E07\u0180\u0183\u0253]/g },
    { 'base': 'c', 'letters': /[\u0063\u24D2\uFF43\u0107\u0109\u010B\u010D\u00E7\u1E09\u0188\u023C\uA73F\u2184]/g },
    { 'base': 'd', 'letters': /[\u0064\u24D3\uFF44\u1E0B\u010F\u1E0D\u1E11\u1E13\u1E0F\u0111\u018C\u0256\u0257\uA77A]/g },
    { 'base': 'dz', 'letters': /[\u01F3\u01C6]/g },
    { 'base': 'e', 'letters': /[\u0065\u24D4\uFF45\u00E8\u00E9\u00EA\u1EC1\u1EBF\u1EC5\u1EC3\u1EBD\u0113\u1E15\u1E17\u0115\u0117\u00EB\u1EBB\u011B\u0205\u0207\u1EB9\u1EC7\u0229\u1E1D\u0119\u1E19\u1E1B\u0247\u025B\u01DD]/g },
    { 'base': 'f', 'letters': /[\u0066\u24D5\uFF46\u1E1F\u0192\uA77C]/g },
    { 'base': 'g', 'letters': /[\u0067\u24D6\uFF47\u01F5\u011D\u1E21\u011F\u0121\u01E7\u0123\u01E5\u0260\uA7A1\u1D79\uA77F]/g },
    { 'base': 'h', 'letters': /[\u0068\u24D7\uFF48\u0125\u1E23\u1E27\u021F\u1E25\u1E29\u1E2B\u1E96\u0127\u2C68\u2C76\u0265]/g },
    { 'base': 'hv', 'letters': /[\u0195]/g },
    { 'base': 'i', 'letters': /[\u0069\u24D8\uFF49\u00EC\u00ED\u00EE\u0129\u012B\u012D\u00EF\u1E2F\u1EC9\u01D0\u0209\u020B\u1ECB\u012F\u1E2D\u0268\u0131]/g },
    { 'base': 'j', 'letters': /[\u006A\u24D9\uFF4A\u0135\u01F0\u0249]/g },
    { 'base': 'k', 'letters': /[\u006B\u24DA\uFF4B\u1E31\u01E9\u1E33\u0137\u1E35\u0199\u2C6A\uA741\uA743\uA745\uA7A3]/g },
    { 'base': 'l', 'letters': /[\u006C\u24DB\uFF4C\u0140\u013A\u013E\u1E37\u1E39\u013C\u1E3D\u1E3B\u017F\u0142\u019A\u026B\u2C61\uA749\uA781\uA747]/g },
    { 'base': 'lj', 'letters': /[\u01C9]/g },
    { 'base': 'm', 'letters': /[\u006D\u24DC\uFF4D\u1E3F\u1E41\u1E43\u0271\u026F]/g },
    { 'base': 'n', 'letters': /[\u006E\u24DD\uFF4E\u01F9\u0144\u00F1\u1E45\u0148\u1E47\u0146\u1E4B\u1E49\u019E\u0272\u0149\uA791\uA7A5]/g },
    { 'base': 'nj', 'letters': /[\u01CC]/g },
    { 'base': 'o', 'letters': /[\u006F\u24DE\uFF4F\u00F2\u00F3\u00F4\u1ED3\u1ED1\u1ED7\u1ED5\u00F5\u1E4D\u022D\u1E4F\u014D\u1E51\u1E53\u014F\u022F\u0231\u00F6\u022B\u1ECF\u0151\u01D2\u020D\u020F\u01A1\u1EDD\u1EDB\u1EE1\u1EDF\u1EE3\u1ECD\u1ED9\u01EB\u01ED\u00F8\u01FF\u0254\uA74B\uA74D\u0275]/g },
    { 'base': 'oi', 'letters': /[\u01A3]/g },
    { 'base': 'ou', 'letters': /[\u0223]/g },
    { 'base': 'oo', 'letters': /[\uA74F]/g },
    { 'base': 'p', 'letters': /[\u0070\u24DF\uFF50\u1E55\u1E57\u01A5\u1D7D\uA751\uA753\uA755]/g },
    { 'base': 'q', 'letters': /[\u0071\u24E0\uFF51\u024B\uA757\uA759]/g },
    { 'base': 'r', 'letters': /[\u0072\u24E1\uFF52\u0155\u1E59\u0159\u0211\u0213\u1E5B\u1E5D\u0157\u1E5F\u024D\u027D\uA75B\uA7A7\uA783]/g },
    { 'base': 's', 'letters': /[\u0073\u24E2\uFF53\u00DF\u015B\u1E65\u015D\u1E61\u0161\u1E67\u1E63\u1E69\u0219\u015F\u023F\uA7A9\uA785\u1E9B]/g },
    { 'base': 't', 'letters': /[\u0074\u24E3\uFF54\u1E6B\u1E97\u0165\u1E6D\u021B\u0163\u1E71\u1E6F\u0167\u01AD\u0288\u2C66\uA787]/g },
    { 'base': 'tz', 'letters': /[\uA729]/g },
    { 'base': 'u', 'letters': /[\u0075\u24E4\uFF55\u00F9\u00FA\u00FB\u0169\u1E79\u016B\u1E7B\u016D\u00FC\u01DC\u01D8\u01D6\u01DA\u1EE7\u016F\u0171\u01D4\u0215\u0217\u01B0\u1EEB\u1EE9\u1EEF\u1EED\u1EF1\u1EE5\u1E73\u0173\u1E77\u1E75\u0289]/g },
    { 'base': 'v', 'letters': /[\u0076\u24E5\uFF56\u1E7D\u1E7F\u028B\uA75F\u028C]/g },
    { 'base': 'vy', 'letters': /[\uA761]/g },
    { 'base': 'w', 'letters': /[\u0077\u24E6\uFF57\u1E81\u1E83\u0175\u1E87\u1E85\u1E98\u1E89\u2C73]/g },
    { 'base': 'x', 'letters': /[\u0078\u24E7\uFF58\u1E8B\u1E8D]/g },
    { 'base': 'y', 'letters': /[\u0079\u24E8\uFF59\u1EF3\u00FD\u0177\u1EF9\u0233\u1E8F\u00FF\u1EF7\u1E99\u1EF5\u01B4\u024F\u1EFF]/g },
    { 'base': 'z', 'letters': /[\u007A\u24E9\uFF5A\u017A\u1E91\u017C\u017E\u1E93\u1E95\u01B6\u0225\u0240\u2C6C\uA763]/g }
];
let changes;


const removeDiacritics = str => {
    if (!changes) {
        changes = defaultDiacriticsRemovalMap;
    }
    for (let i = 0; i < changes.length; i++) {
        str = str.replace(changes[i].letters, changes[i].base);
    }
    return str.toLowerCase();
}


exports.removeDiacritics = removeDiacritics;

exports.addModelLog = (modelName, aKeys, data) => {

    modelName = _.camelCase(modelName);

    let path = '/modelLog/' + modelName;

    aKeys.forEach(k => {
        path += '/' + _.camelCase(data[k]);
    })

    admin.database().ref(path).set(data);

    return path;

}

exports.sendSms = (id, attr, request) => {
    const host = (typeof request === 'boolean' && request ? 'forcesend' : this.getHost(request));
    const req = require("request");

    attr.from = attr.from || 'yCard';

    return new Promise(resolve => {

        if (!attr.to) {
            return resolve('attr.to não informado...');
        }

        attr.to = attr.to.onlyNumbers();

        const options = {
            url: 'https://sms.comtele.com.br/api/v2/customsend/' + id,
            method: 'POST',
            body: attr,
            json: true
        };

        if (host === 'localhost') {
            console.info('sendSms on localhost [' + id + ']', attr);
            options.to = '11945813260';
            console.info('Número substituido por 11 9 4581-3260');
        }

        return req(options, (error, response, body) => {
            if (!error) {
                resolve(body);
            } else {
                resolve(error);
            }
        });

    })

}


exports.generateKeywords = function (v1, v2, v3, v4, v5, v6, v7) {

    const results = [];

    let values = [];

    const addValue = v => {
        if (v) {
            values.push(v);
            values = values.concat(v.split(' '));
        }
    }

    addValue(v1);
    addValue(v2);
    addValue(v3);
    addValue(v4);
    addValue(v5);
    addValue(v6);
    addValue(v7);

    values.forEach(v => {
        v = removeDiacritics(v);
        for (let i = 3; i <= v.length && i <= 12; i++) {
            const value = v.substr(0, i).trim();
            if (!results.includes(value)) {
                results.push(value);
            }
        }
    })

    return results;
}


exports.config = {
    get: path => {
        path = splitReplace(path, '.', '_');

        if (path.startsWith('/')) {
            path = path.substr(1);
        }

        path = `/globalConfig/${path}`;

        return new Promise(resolve => {
            return admin.database().ref(path).once("value", data => {
                return resolve(data.val() || null);
            })
        })
    }
}

exports.now = _ => {
    return Timestamp.now();
}

exports.nowTimestamp = _ => {
    return Timestamp.now();
}

exports.nowMilliseconds = (addValue, addType) => {
    const hoje = moment(Timestamp.now().toDate());

    if (addValue && addType) {
        hoje.add(addValue, addType || 'minutes');
    }

    return hoje.valueOf();
}

exports.nowDateTime = _ => {
    const hoje = moment(Timestamp.now().toDate());

    return hoje.format('YYYY-MM-DD HH:mm:ss');
}

exports.guid = _ => {
    let d = new Date().getTime(); // Timestamp
    let d2 = (performance && performance.now && (performance.now() * 1000)) || 0; // Time in microseconds since page-load or 0 if unsupported

    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
        let r = Math.random() * 16; // random number between 0 and 16
        if (d > 0) { // Use timestamp until depleted
            r = (d + r) % 16 | 0;
            d = Math.floor(d / 16);
        } else { // Use microseconds since page-load if supported
            r = (d2 + r) % 16 | 0;
            d2 = Math.floor(d2 / 16);
        }
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
};


exports.isCPFValido = cpf => {

    if (typeof cpf !== "string") return false;

    cpf = cpf.replace(/[\s.-]*/igm, '')

    const invalid = [];

    for (let i = 0; i <= 9; i++) {
        invalid.push(i.toString().repeat(11));
    }

    if (!cpf || cpf.length !== 11 || invalid.includes(cpf)) {
        return false
    }

    let soma = 0, resto, i;

    for (i = 1; i <= 9; i++) {
        soma = soma + parseInt(cpf.substring(i - 1, i)) * (11 - i);
    }

    resto = (soma * 10) % 11;

    if ((resto === 10) || (resto === 11)) resto = 0;

    if (resto !== parseInt(cpf.substring(9, 10))) { return false; }

    soma = 0;

    for (i = 1; i <= 10; i++) {
        soma = soma + parseInt(cpf.substring(i - 1, i)) * (12 - i);
    }

    resto = (soma * 10) % 11;
    if ((resto === 10) || (resto === 11)) {
        resto = 0;
    }

    if (resto !== parseInt(cpf.substring(10, 11))) {
        return false;
    }

    return true;
}

exports.isCNPJValido = cnpj => {

    cnpj = cnpj.replace(/[^\d]+/g, '');

    if (cnpj === '' || cnpj.length !== 14) return false;

    let soma,
        pos,
        tamanho,
        numeros,
        resultado;

    // Elimina CNPJs invalidos conhecidos
    if (cnpj === "00000000000000" ||
        cnpj === "11111111111111" ||
        cnpj === "22222222222222" ||
        cnpj === "33333333333333" ||
        cnpj === "44444444444444" ||
        cnpj === "55555555555555" ||
        cnpj === "66666666666666" ||
        cnpj === "77777777777777" ||
        cnpj === "88888888888888" ||
        cnpj === "99999999999999"
    ) {
        return false;
    }

    // Valida DVs
    const digitos = cnpj.substring(tamanho);

    tamanho = cnpj.length - 2;
    numeros = cnpj.substring(0, tamanho);
    soma = 0;
    pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
        soma += numeros.charAt(tamanho - i) * pos--;
        if (pos < 2) pos = 9;
    }

    resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;

    if (parseInt(resultado) !== parseInt(digitos.charAt(0))) return false;

    tamanho = tamanho + 1;
    numeros = cnpj.substring(0, tamanho);
    soma = 0;
    pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
        soma += numeros.charAt(tamanho - i) * pos--;
        if (pos < 2) pos = 9;

    }

    resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;

    if (parseInt(resultado) !== parseInt(digitos.charAt(1))) return false;

    return true;

}


exports.base64ToJson = data => {
    const result = {};
    let messageData;

    if (!data) return result;

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

exports.calcDtVencimento = (dia, mes, ano, addMonths) => {

    const dtRef = moment({ year: ano, month: mes - 1, day: 1, hour: 3, minute: 0, second: 0, millisecond: 0 }).tz("America/Sao_Paulo");

    let dtVencimento,
        d = parseInt(dia);

    dtRef.add(addMonths, 'month');

    dtVencimento = moment(dtRef);
    dtVencimento.set("date", d); // Se o dia não existir no mês, o Moment manda para o dia 1º do próximo mês

    while (dtRef.month() !== dtVencimento.month()) {
        d--;
        dtVencimento = moment(dtRef);
        dtVencimento.set("date", d);
    }

    return dtVencimento;
}


const projectId = 'premios-fans';
const { Logging } = require('@google-cloud/logging');
const logging = new Logging({ projectId });
const log = logging.log('premiosfansbackend');

async function writeLog(text, severity, labels) {

    const metadata = {
        resource: {
            type: 'global'
        },
        severity: severity
    };

    if (labels) {
        metadata.labels = labels;
    }

    const entry = log.entry(metadata, text);

    await log.write(entry);
}

exports.log = {
    log: (text, labels) => { return writeLog(text, 'DEFAULT', labels); },
    default: (text, labels) => { return writeLog(text, 'DEFAULT', labels); },
    debug: (text, labels) => { return writeLog(text, 'DEBUG', labels); },
    info: (text, labels) => { return writeLog(text, 'INFO', labels); },
    notice: (text, labels) => { return writeLog(text, 'NOTICE', labels); },
    warning: (text, labels) => { return writeLog(text, 'WARNING', labels); },
    error: (text, labels) => { return writeLog(text, 'ERROR', labels); },
    critical: (text, labels) => { return writeLog(text, 'CRITICAL', labels); },
    alert: (text, labels) => { return writeLog(text, 'ALERT', labels); },
    emergency: (text, labels) => { return writeLog(text, 'EMERGENCY', labels); }
}
