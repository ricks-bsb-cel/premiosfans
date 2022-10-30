'use strict';

const global = require('./global');

const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();
const parent = 'projects/801994869227';

// https://www.npmjs.com/package/@google-cloud/secret-manager
// https://github.com/googleapis/nodejs-secret-manager

const get = (name, notFoundException) => {
    return new Promise((resolve, reject) => {
        try {

            notFoundException = typeof notFoundException === 'boolean' ? notFoundException : true;

            // Adiciona o código do projeto e a última versão
            name = `${parent}/secrets/${name}/versions/latest`;

            var secret = null;

            return client.accessSecretVersion({ name: name })

                .then(secretResult => {

                    secret = secretResult[0].payload.data.toString();
                    secret = JSON.parse(secret);

                    return resolve(secret);
                })

                .catch(e => {
                    if (secret) {
                        return resolve(secret);
                    } else {
                        if (e.code === 5) {
                            if (notFoundException) {
                                // Retorna erro 420 caso ainda não exista o secret do cliente
                                return reject(global.newError('secret not found', 420));
                            } else {
                                return resolve(null);
                            }
                        } else {
                            return reject(e);
                        }
                    }
                })

        }
        catch (e) {
            console.error(e);
            return reject(e);
        }
    })
}

exports.requestGet = (request, response) => {
    const host = global.getHost(request, response);

    if (host !== 'localhost') {
        return response.status(500).json(global.defaultResult({ error: 'ERROR: 48452XX' }));
    }

    let name = request.params.name || null;

    return get(name)
        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: {
                        key: `${parent}/secrets/${name}/versions/latest`,
                        value: result
                    }
                }, true)
            );
        })
        .catch(e => {
            return response.status(500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })
}



const exists = name => {
    return new Promise((resolve, reject) => {
        try {

            name = `${parent}/secrets/${name}/versions/latest`;

            return client.accessSecretVersion({
                name: name
            })
                .then(_ => {
                    return resolve(true);
                })
                .catch(e => {
                    if (e.code === 5) {
                        return resolve(false);
                    } else {
                        return reject(e);
                    }
                })

        }
        catch (e) {
            console.error(e);
            return reject(e);
        }
    })
}

exports.requestExists = (request, response) => {
    const host = global.getHost(request, response);

    if (host !== 'localhost') {
        return response.status(500).json(global.defaultResult({ error: 'ERROR: 48452XX' }));
    }

    let name = request.params.name || null;

    return exists(name)
        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: {
                        exists: result
                    }
                }, true)
            );
        })
        .catch(e => {
            return response.status(500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })
}


const kill = name => {
    return new Promise((resolve, reject) => {
        try {

            name = `${parent}/secrets/${name}`;

            return client.deleteSecret({
                name: name
            })
                .then(_ => {
                    return resolve(true);
                })
                .catch(e => {
                    if (e.code === 5) {
                        return resolve(false);
                    } else {
                        return reject(e);
                    }
                })

        }
        catch (e) {
            console.error(e);
            return reject(e);
        }
    })
}


const secretExists = secretId => {
    return new Promise((resolve, reject) => {
        return client.getSecret({ name: `${parent}/secrets/${secretId}` })

            .then(_ => {
                return resolve(true);
            })

            .catch(e => {
                if (e.code === 5) {
                    return resolve(false)
                } {
                    console.error(e);
                    return reject(e);
                }
            })
    })
}


const createSecret = secretId => {
    let secretName = null;

    return new Promise((resolve, reject) => {

        const options = {
            parent: parent,
            secret: { name: secretId, replication: { automatic: {}, }, },
            secretId
        };

        return client.createSecret(options)

            .then(createSecretResult => {
                secretName = createSecretResult[0].name;

                return resolve(secretName);
            })

            .catch(e => {
                console.error(e);
                return reject(e);
            })
    })

}


const createOrUpdate = (secretId, data) => {
    return new Promise((resolve, reject) => {

        var doesSecretExists,
            secretName = null,
            secretNameCreated = null;

        return secretExists(secretId)

            .then(resultSecretExists => {

                doesSecretExists = resultSecretExists;

                if (doesSecretExists) {
                    return `${parent}/secrets/${secretId}`;
                } else {
                    return createSecret(secretId);
                }

            })

            .then(secretData => {
                secretName = secretData;

                return get(secretId, false); // Busca a última versão existente
            })

            .then(lastVersionData => {

                let payload;

                if (lastVersionData) {
                    data = Object.assign(lastVersionData, data);
                }

                try {
                    payload = Buffer.from(JSON.stringify(data), 'utf8');
                } catch (e) {
                    throw new e;
                }

                return client.addSecretVersion({
                    parent: secretName,
                    payload: {
                        data: payload,
                    },
                });

            })

            .then(resultAddSecretVersion => {
                secretNameCreated = resultAddSecretVersion[0].name;

                return client.listSecretVersions({
                    parent: secretName,
                });
            })

            .then(resultListSecretVersions => {

                let versions = (resultListSecretVersions[0] || []),
                    promisses = [],
                    lastEnabledVersion = 0,
                    id;

                // Calcula a ultima versão desabilitada
                versions
                    .filter(f => { return f.state === 'ENABLED' })
                    .forEach(v => {
                        id = parseInt(v.name.split('/').pop());
                        if (lastEnabledVersion < id) {
                            lastEnabledVersion = id;
                        }
                    })

                lastEnabledVersion -= 2;

                versions.forEach(v => {
                    if (v.name !== secretNameCreated && v.state === 'ENABLED') {
                        id = parseInt(v.name.split('/').pop());
                        if (id <= lastEnabledVersion) {
                            promisses.push(client.destroySecretVersion({ name: v.name }));
                        }
                    }
                })

                return Promise.all(promisses);
            })

            .then(_ => {
                return resolve(secretNameCreated);
            })

            .catch(e => {
                return reject(e);
            })

    })
}

exports.requestCreateOrUpdate = (request, response) => {

    const host = global.getHost(request, response);

    if (host !== 'localhost') {
        return response.status(500).json(global.defaultResult({ error: 'ERROR: 48452XX' }));
    }

    let name = request.params.name || null;
    let data = request.body || null;

    if (!data) {
        return response.status(500).json(
            global.defaultResult({
                error: 'Informe os dados a serem armazenados em body'
            })
        );
    }

    return createOrUpdate(name, data)

        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: {
                        secretKey: result
                    }
                }, true)
            );
        })

        .catch(e => {
            return response.status(500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })

}

exports.get = get;
exports.exists = exists;
exports.createOrUpdate = createOrUpdate;
exports.kill = kill;
