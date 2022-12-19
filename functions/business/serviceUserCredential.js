'use strict';

const secretManager = require('../secretManager');
const joiHelper = require('./joiHelper');
const global = require('../global');

const firestoreDAL = require('../api/firestoreDAL');
const collectionServiceUserCredential = firestoreDAL.serviceUserCredential();

const schema = _ => {
    return Joi
        .object({

            tipo: Joi.any()
                .valid('cartos')
                .required()
                .messages({ 'any.only': 'Tipo inválido' })
                .default('cartos')
                .description('Tipo da PIX'),

            cpf: joiHelper.cpf({
                required: true,
                description: 'CPF'
            }),

            uid: joiHelper.id({
                required: false,
                description: 'UID do usuário Firebase. Exemplo: AqQuKLxnxWRmf2mxK6JsN3jXpcI2.'
            }),

            user: Joi.string()
                .max(128)
                .required()
                .messages({
                    'string.max': 'O nome deve ter no máximo 64 caracteres',
                })
                .description('Usuário no serviço'),

            password: Joi.string()
                .required()
                .description('Senha (encriptada!) o serviço'),


        })
        .messages({
            'object.unknown': 'Atributo inválido',
            'any.required': 'Existe um ou mais atributos obrigatórios não informados'
        })
        .description('Criação de Chave Pix');
}

const set = data => {
    return new Promise((resolve, reject) => {

        let id,
            doc,
            toUpdate,
            encryptPassword = false;

        return schema().validateAsync(data)

            .then(validateResult => {

                toUpdate = validateResult;

                return collectionServiceUserCredential.get({
                    filter: {
                        tipo: toUpdate.tipo,
                        cpf: toUpdate.cpf
                    },
                    limit: 1
                });

            })

            .then(getResult => {

                doc = getResult.length ? getResult[0] : null;
                id = doc ? doc.id : null;

                if (!doc || doc.password !== toUpdate.password) {
                    encryptPassword = true;
                    return secretManager.get('service-user-credential-keys');
                } else {
                    return null;
                }
            })

            .then(secretManagerResult => {

                if (encryptPassword) {
                    const secret = secretManagerResult[`r${toUpdate.cpf.slice(-1)}`];
                    toUpdate.password = global.encryptString(toUpdate.password, secret)
                }

                if (id) {
                    return collectionServiceUserCredential.merge(id, toUpdate);
                } else {
                    return collectionServiceUserCredential.add(toUpdate);
                }

            })

            .then(updateResult => {
                return resolve(updateResult);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

async function getByCpf(tipo, cpf) {
    if (!tipo || !cpf) throw new Error('Informe tipo e cpf');

    const getResult = await collectionServiceUserCredential.get({
        filter: { tipo: tipo, cpf: cpf },
        limit: 1
    });

    const credentials = getResult.length ? getResult[0] : null;

    if (credentials) {
        const secretManagerResult = await secretManager.get('service-user-credential-keys');
        if (secretManagerResult) {
            const secret = secretManagerResult[`r${cpf.slice(-1)}`];
            credentials.password = global.decryptString(credentials.password, secret)
        }
    }

    return credentials;
}

/*
const getByCpf = (tipo, cpf) => {
    return new Promise((resolve, reject) => {
 
        if (!tipo || !cpf) {
            throw new Error('Informe tipo e cpf');
        }
 
        let credentials;
 
        return collectionServiceUserCredential.get({
            filter: { tipo: tipo, cpf: cpf },
            limit: 1
        })
 
            .then(getResult => {
 
                credentials = getResult.length ? getResult[0] : null;
 
                if (!credentials) {
                    return null;
                }
 
                return secretManager.get('service-user-credential-keys');
            })
 
            .then(secretManagerResult => {
 
                if (secretManagerResult) {
                    const secret = secretManagerResult[`r${cpf.slice(-1)}`];
                    credentials.password = global.decryptString(credentials.password, secret)
                }
 
                return resolve(credentials);
 
            })
 
            .catch(e => {
                return reject(e);
            })
 
    })
}
*/

const getByUid = (tipo, uid) => {
    return new Promise((resolve, reject) => {

        let credentials;

        return collectionServiceUserCredential.get({
            filter: { tipo: tipo, uid: uid },
            limit: 1
        })

            .then(getResult => {
                credentials = getResult.length ? getResult[0] : null;

                if (!credentials) {
                    return null;
                }

                return secretManager.get('service-user-credential-keys');
            })

            .then(secretManagerResult => {

                if (secretManagerResult) {
                    const secret = secretManagerResult[`r${credentials.cpf.slice(-1)}`];
                    credentials.password = utils.decryptString(credentials.password, secret)
                }

                return resolve(credentials);

            })

            .catch(e => {
                return reject(e);
            })

    })
}

exports.set = set;
exports.getByCpf = getByCpf;
exports.getByUid = getByUid;
