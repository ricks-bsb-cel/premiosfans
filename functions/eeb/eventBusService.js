"use strict";

// https://cloud.google.com/pubsub/docs/publisher
// https://www.npmjs.com/package/@google-cloud/pubsub
// https://cloud.google.com/nodejs/docs/reference/tasks/latest

const admin = require("firebase-admin");

const initFirebase = require("../initFirebase");
const { PubSub } = require('@google-cloud/pubsub');
const { CloudTasksClient } = require('@google-cloud/tasks');

const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
const helper = require('./eventBusServiceHelper');

const projectName = 'premios-fans';
const projectLocation = 'us-central1';

// check noAuth
const _authType = {
    noAuth: 1, // Pode ser executada livremente, sem nenhum tipo de token
    internal: 2, // Deve ser disparada de outra rotina ou do PubSub. Se estiver em localhost, exige autenticação de SuperUsuári
    token: 3, // Exige um token de autenticação (qualquer um)
    tokenNotAnonymous: 4, // Exige um token de autenticação de usuário não anônimo
    tokenAnonymous: 5, // Exige um token de autenticacação de usuário anônimo
    superUser: 6 // Exige um token de autenticação de super usuário
};

const authTypeDesc = authType => {
    let result = null;
    Object.keys(_authType).forEach(k => {
        if (_authType[k] === authType) result = k;
    })
    return result;
}

/*
const pubSubRegion = 'us-central1-pubsub.googleapis.com:443';
const pubSubClient = new PubSub({ apiEndpoint: pubSubRegion });
*/

const pubSubClient = new PubSub();
const topicsCache = [];

/*
O eventBusService é um "envelope" de disparo de métodos utilizando o PubSub
- Os métodos devem ser "registrados" como classes herdadas do serviceRunner
- A classe é reinstanciada pelo PubSub e executada de acordo com os parametros
*/

const checkAuthentication = (request, response, authType) => {
    return new Promise((resolve, reject) => {
        const result = {
            user_uid: 'public',
            user_isAnonymous: true,
            user_isSuperUser: false
        };

        if (typeof authType === 'undefined') return reject(new Error('Invalid authType'));

        // Sem autenticação
        if (authType === _authType.noAuth) return resolve(result);

        // Libera Autenticação interna sem request (chamada interna)
        if (authType === _authType.internal && !request) return resolve(result);

        // Daqui em diante, é exigido um token
        const token = helper.getUserTokenFromRequest(request, response);

        if (!token) return reject(new Error('Token required'));

        return admin.auth().verifyIdToken(token)

            .then(userTokenDetails => {
                const isAnonymous = userTokenDetails.provider_id === 'anonymous' || userTokenDetails.firebase.sign_in_provider === 'anonymous';
                const isSuperUser = typeof userTokenDetails.superUser === 'boolean' ? userTokenDetails.superUser : false;

                result.user_uid = userTokenDetails.uid;
                result.user_isAnonymous = isAnonymous;
                result.user_isSuperUser = isSuperUser;

                switch (authType) {
                    case _authType.noAuth:
                        return resolve(result);

                    case _authType.internal:
                        if (isSuperUser) {
                            return resolve(result);
                        } else {
                            return reject(new Error(`Request for internal auth calls is for superuser only. Current user uid [${result.user_uid}]`));
                        }

                    case _authType.token:
                        return resolve(result);

                    case _authType.tokenNotAnonymous:
                        if (isAnonymous) {
                            return reject(new Error('Anonymous tokens not allowed'));
                        } else {
                            return resolve(result);
                        }

                    case _authType.tokenAnonymous:
                        if (isAnonymous) {
                            return resolve(result);
                        } else {
                            return reject(new Error('Only Anonymous tokens allowed'));
                        }

                    case _authType.superUser:
                        if (isSuperUser && !isAnonymous) {
                            return resolve(result);
                        } else {
                            return reject(new Error(`Only SuperUser allowed. Current user uid  ${result.user_uid}`));
                        }

                    default:
                        return reject(new Error('Invalid auth mode'));

                }

            })

            .catch(e => {
                if (e.code === 'auth/id-token-expired') {
                    return reject(new Error('Token expired'));
                } else {
                    return reject(e);
                }
            })

    })
}

class eventBusService {

    constructor(req, resp, p, js) {
        if (this.constructor === 'eventBusService') throw new Error("Can't instantiate abstract class eventBusService!");

        this.request = req && req.constructor.name === 'IncomingMessage' ? req : false;
        this.response = resp && resp.constructor.name === 'ServerResponse' ? resp : false;

        this.admin = null;
        this.parm = p || {};

        this.result = {};

        this.parm.name = p.name;
        this.parm.method = js;

        this.parm.ordered = typeof this.parm.ordered !== 'boolean' ? false : this.parm.ordered;
        this.parm.orderingKey = this.parm.orderingKey || null;
        this.parm.attributes = this.parm.attributes || {};

        this.parm.topic = `eeb-${this.parm.name}`
        this.parm.topicSubscription = `eeb-subscription-${this.parm.name}`
    }

    getTopic() {
        const i = topicsCache.findIndex(f => { return f.name === this.parm.topic });

        if (i >= 0) {
            return topicsCache[i].obj;
        } else {
            topicsCache.push({
                name: this.parm.topic,
                obj: pubSubClient.topic(this.parm.topic, { batching: { maxMessages: 1 } })
            })
            return this.getTopic();
        }
    }

    log(text, type, labels) {

        let l = {
            method: this.parm.method,
            serviceId: this.parm.serviceId,
            topic: this.parm.topic
        };

        if (labels) {
            l = Object.assign(l, labels);
        }

        helper.log(text, type, l);
    }

    init() {

        return new Promise((resolve, reject) => {

            let result;

            return initFirebase.init()
                .then(app => {
                    this.admin = app;

                    return eventBusServiceParmSchema().validateAsync(this.parm, { abortEarly: false });
                })

                .then(validateResult => {
                    this.parm = validateResult;
                    this.parm.serviceId = this.parm.serviceId || uuidv4();
                    this.parm.authDescription = authTypeDesc(this.parm.auth);

                    if (this.parm.delay > 0 && !this.parm.async) throw new Error('Chamadas com delay tem que ser assincronas (async = true)');

                    return checkAuthentication(this.request, this.response, this.parm.auth);
                })

                .then(userInfoResult => {
                    this.parm = { ...this.parm, ...userInfoResult };

                    this.parm.attributes.user_uid = userInfoResult.user_uid;

                    // Dispara de acordo com o o tipo.
                    if (this.parm.async) { // Async... envia para o Pub/Sub
                        if (this.parm.delay) {
                            return this._sentToTask();
                        } else {
                            return this._startPublish();
                        }
                    } else { // Sync... executa imediatamente
                        return this._startRun();
                    }
                })

                .then(startResult => {
                    result = startResult;
                    result.async = this.parm.async;

                    return resolve(
                        this.response ?
                            this.response.status(200).json(result) :
                            (result.async ? null : result)
                    );
                })

                .catch(e => {
                    const error = e.message || e.details || 'unknow';
                    this.log('error', helper.logType.error, { error: { code: e.code, message: error } });

                    if (this.response) {
                        return this.response.status(500).json({
                            success: false,
                            error: e.toString()
                        })
                    } else {

                        return reject(new Error(error));
                    }
                })

        })

    }

    _sentToTask() {
        return new Promise((resolve, reject) => {
            const client = new CloudTasksClient();
            const parent = client.queuePath(projectName, projectLocation, this.parm.taskQueueName);

            const payload = {
                data: this.parm.data,
                attributes: Object.assign(
                    {
                        topic: this.parm.topic,
                        method: this.parm.method,
                        serviceId: this.parm.serviceId
                    },
                    this.parm.attributes || {}
                )
            };

            const task = {
                httpRequest: {
                    headers: { 'Content-Type': 'text/plain' },
                    httpMethod: 'POST',
                    body: Buffer.from(JSON.stringify(payload)),
                    url: `https://us-central1-premios-fans.cloudfunctions.net/eeb/api/eeb/v1/task-receiver/${this.parm.method}`
                },
                scheduleTime: {
                    seconds: parseInt(this.parm.delay) + Date.now() / 1000
                }
            };

            const request = {
                parent: parent,
                task: task
            };

            return client.createTask(request)
                .then(createTaskResponse => {
                    return resolve(createTaskResponse);
                })
                .catch(e => {
                    if (e.code === 9) {
                        return createTaskQueue(this.parm.taskQueueName);
                    }

                    return reject(e);
                })
                .then(result => {
                    return resolve(result);
                })
                .catch(e => {
                    return reject(e);
                })

        })
    }

    publish() {
        return new Promise((resolve, reject) => {

            const publishData = {
                data: this.parm.data ? Buffer.from(JSON.stringify(this.parm.data), 'utf8') : null,
                attributes: Object.assign(
                    {
                        topic: this.parm.topic,
                        method: this.parm.method,
                        serviceId: this.parm.serviceId
                    },
                    this.parm.attributes || {}
                )
            };

            if (this.parm.orderingKey) {
                publishData.orderingKey = this.parm.orderingKey;
            }

            // garante que os attributes contenham apenas strings
            Object.keys(publishData.attributes).forEach(k => {
                if (typeof publishData.attributes[k] !== 'string') {
                    publishData.attributes[k] = publishData.attributes[k].toString();
                }
            });

            const topic = this.getTopic();

            this.log('publish-start');

            return topic.publishMessage(publishData)

                .then(messageId => {
                    this.parm.messageId = messageId;

                    this.log('publish-success');

                    return {
                        topic: this.parm.topic,
                        messageId: this.parm.messageId,
                        serviceId: this.parm.serviceId
                    };
                })

                .catch(e => {
                    if (e.code === 5) {
                        console.info(`Topic ${this.parm.topic} not found. Creating...`);

                        return createTopic(
                            this.parm.topic, // Nome do tópico
                            this.parm.topicSubscription, // Nome da Subscrição do Tópico
                            this.parm.method, // Método (utilizado no post da Subscrição)
                            this.parm.ordered // Se está ordenado ou não
                        );
                    } else {
                        return reject(e);
                    }
                })

                .then(result => {
                    return resolve(result);
                })

                .catch(e => {
                    return reject(e);
                })


        })
    }

    _startRun() {
        return new Promise((resolve, reject) => {

            let result;

            return this.run(this.admin)

                .then(runResult => {
                    result = {
                        result: runResult,
                        code: 200
                    };

                    if (this.parm.debug) { result.debug = this.parm; }

                    return resolve(result);
                })

                .catch(e => {
                    return reject(e);
                });

        })
    }

    _startPublish() {
        return new Promise((resolve, reject) => {

            this.publish()
                .then(result => {
                    const r = { result: result, code: 200 }

                    if (this.parm.debug) {
                        r.debug = this.parm;
                    }

                    return resolve(r);
                })
                .catch(e => {
                    return reject(e);
                });

        })
    }

    run() {
        throw new Error(`Implemente o run na classe herdada`);
    }

}

const eventBusServiceParmSchema = _ => {
    const schema = Joi
        .object({
            name: Joi.string().required(),
            data: Joi.object().required(),
            attributes: Joi.object(),
            method: Joi.string(),
            topic: Joi.string().required(),
            topicSubscription: Joi.string().required(),
            async: Joi.boolean().default(false),
            debug: Joi.boolean().default(false),
            ordered: Joi.boolean().default(false),
            orderingKey: Joi.string().allow(null),
            delay: Joi.number().integer().min(0).default(0),
            taskQueueName: Joi.string().default('eeb'),
            auth: Joi.number().integer().min(1).max(6).required() // Tipo de Autenticação
        });

    /*
    Chamadas do tipo internal tem as seguintes características
        - Não precisam de autenticação (noAuth tem que ser true)
        - Podem ser disparadas apenas de outras rotinas
        - Se disparada de LocalHost, exige token de autenticação de um SuperUser
    */

    return schema;
}

const createTopic = (topic, subscription, method, ordered) => {
    return new Promise((resolve, reject) => {

        const options = { name: topic };

        pubSubClient
            .createTopic(options)
            .then(_ => {
                return createSubscription(topic, subscription, method, ordered);
            })
            .then(_ => {
                return resolve({
                    topicName: topic,
                    message: `Topic ${topic} created. Don't forget to assign Subscriber Role and add Publisher Permission`
                })
            })
            .catch(e => {
                return reject(e);
            })
    })
}

const createSubscription = (topic, subscription, method, ordered) => {
    return new Promise((resolve, reject) => {

        // https://googleapis.dev/nodejs/pubsub/latest/index.html

        const options = {
            name: subscription,
            pushConfig: {
                pushEndpoint: `https://us-central1-premios-fans.cloudfunctions.net/eeb/api/eeb/v1/receiver/${method}`
            },
            topic: topic,
            messageRetentionDuration: { seconds: 7 * 24 * 60 * 60, nanos: 0 },
            retainAckedMessages: false,
            ackDeadlineSeconds: 30,
            expirationPolicy: { seconds: 0, nanos: 0 },
            deadLetterPolicy: {
                deadLetterTopic: 'projects/premios-fans/topics/eeb-dead-lettering',
                maxDeliveryAttempts: 5
            },
            retryPolicy: {
                minimumBackoff: { seconds: 100, nanos: 0 },
                maximumBackoff: { seconds: 300, nanos: 0 },
            }
        };

        if (ordered) {
            options.enableMessageOrdering = true;
        }

        console.info(`Subscription ${subscription} not found. Creating...`);

        pubSubClient
            .topic(topic)
            .createSubscription(subscription, options)
            .then(_ => {
                return resolve();
            })
            .catch(e => {
                return reject(e);
            })

    })
}

const createTaskQueue = (queueName) => {
    return new Promise((resolve, reject) => {
        const cloudTasks = require('@google-cloud/tasks');
        const client = new cloudTasks.CloudTasksClient();

        const parm = {
            parent: client.locationPath(projectName, projectLocation),
            queue: {
                name: client.queuePath(projectName, projectLocation, queueName),
                appEngineHttpQueue: {
                    appEngineRoutingOverride: {
                        service: 'default'
                    }
                }
            }
        };

        console.info(`Creating queue ${queueName}...`);

        return client.createQueue(parm)
            .then(_ => {
                console.info(`Queue ${queueName} created successfully`);

                return resolve({
                    success: true,
                    message: `Queue ${queueName} created successfully`
                });
            })
            .catch(e => {
                return reject(e);
            })
    })
}

exports.abstract = eventBusService;
exports.authType = _authType;

