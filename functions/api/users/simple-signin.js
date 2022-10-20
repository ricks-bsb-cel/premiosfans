"use strict";

const admin = require("firebase-admin");
const firestoreDAL = require("../firestoreDAL");
const randomstring = require("randomstring");

const global = require('../../global');

const collectionLancamentos = firestoreDAL.lancamentos();
const collectionSimpleSignInUrls = firestoreDAL.simpleSignInUrls();

/* https://firebase.google.com/docs/auth/admin/custom-claims */

exports.requestCheckUser = (request, response) => {

    const cpfCnpj = request.body.cpfCnpj || null;

    if (
        !cpfCnpj ||
        (cpfCnpj.length !== 11 && cpfCnpj !== 14) ||
        (cpfCnpj.length === 11 && !global.isCPFValido(cpfCnpj)) ||
        (cpfCnpj.length === 14 && !global.isCNPJValido(cpfCnpj))
    ) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'invalid request'
        }));
    }

    const dtHoje = admin.firestore.Timestamp.now();

    // Verifica se existe pelo menos um lançamento no CPF/CNPJ do usuario
    return collectionLancamentos.get({
        filter: [
            { field: "cliente_cpfcnpj", condition: "==", value: cpfCnpj },
            { field: "ativo", condition: "==", value: true },
            { field: "dtLiberacaoParaPagamento_timestamp", condition: "<=", value: dtHoje }
        ],
        limit: 1
    })

        .then(resultLancamentos => {

            return response.status(200).json(
                global.defaultResult({
                    data: {
                        success: Boolean(resultLancamentos.length)
                    }
                }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })

}

const getSimpleSignInCodes = cpfCnpj => {
    return new Promise((resolve, reject) => {

        return collectionSimpleSignInUrls.get({
            filter: {
                cpfCnpj: cpfCnpj
            }
        })

            .then(collectionResult => {
                if (collectionResult.length) {
                    return collectionResult[0];
                } else {
                    let newDoc = {
                        cpfCnpj: cpfCnpj,
                        token: randomstring.generate({
                            length: 18
                        })
                    };

                    global.setDateTime(newDoc, 'dtInclusao');
                    global.setDateTime(newDoc, 'dtValidade', 3,);

                    return collectionSimpleSignInUrls.add(newDoc);
                }
            })

            .then(doc => {
                return resolve(doc);
            })

            .catch(e => {
                console.error(e);

                return reject(e);
            })
    })
}

const generateSimpleSignUrl = (fullUrl, cpfCnpj) => {
    return new Promise((resolve, reject) => {

        return getSimpleSignInCodes(cpfCnpj)
            .then(codesResult => {
                return resolve({
                    token: codesResult.token,
                    url: fullUrl.replace('{token}', codesResult.token)
                });
            })

            .catch(e => {
                return reject(e);
            })
    })
}

exports.requestSimpleSignUrl = (request, response) => {

    const cpfCnpj = request.body.cpfCnpj || null;
    const url = request.body.url || null;

    if (
        !cpfCnpj ||
        !url ||
        !url.includes('{token}') ||
        (cpfCnpj.length !== 11 && cpfCnpj !== 14) ||
        (cpfCnpj.length === 11 && !global.isCPFValido(cpfCnpj)) ||
        (cpfCnpj.length === 14 && !global.isCNPJValido(cpfCnpj))
    ) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'invalid request'
        }));
    }

    return generateSimpleSignUrl(url, cpfCnpj)

        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: result
                }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })

}


const validateSimpleSignData = (token, cpfCnpj) => {
    return new Promise((resolve, reject) => {

        if (!cpfCnpj || cpfCnpj.length < 3) {
            throw new Error(`invalid`);
        }

        return collectionSimpleSignInUrls.get({
            filter: { token: token }
        })

            .then(doc => {
                doc = doc.length ? doc[0] : null;

                if (!doc || !doc.cpfCnpj.includes(cpfCnpj)) {
                    throw new Error(`invalid`);
                }

                return resolve({
                    success: true,
                    data: {
                        cpfCnpj: doc.cpfCnpj,
                        token: doc.token,
                        dtInclusao: doc.dtInclusao
                    }
                });
            })

            .catch(e => {
                return reject(e);
            })
    })
}

exports.requestValidateSimpleSignData = (request, response) => {
    const token = request.body.token || null;
    const cpfCnpj = request.body.cpfCnpj || null;

    if (!token || !cpfCnpj) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'invalid request'
        }));
    }

    return validateSimpleSignData(token, cpfCnpj)

        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: result
                }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })
}



exports.generateSimpleSignUrl = generateSimpleSignUrl;
exports.validateSimpleSignData = validateSimpleSignData;