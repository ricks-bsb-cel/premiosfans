"use strict";

// https://cloud.google.com/pubsub/docs/publisher
// https://www.npmjs.com/package/@google-cloud/pubsub

const initFirebase = require("../initFirebase");
const { PubSub } = require('@google-cloud/pubsub');

const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
const helper = require('./eventBusServiceHelper');

const users = require('../api/users/users');

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

class eventBusService {

    constructor(req, resp, p, js) {
        this.request = req && req.constructor.name === 'IncomingMessage' ? req : false;
        this.response = resp && resp.constructor.name === 'ServerResponse' ? resp : false;

        this.admin = null;
        this.parm = p || {};

        this.result = {};

        this.parm.name = p.name;
        this.parm.method = js;

        this.parm.ordered = typeof this.parm.ordered !== 'boolean' ? false : this.parm.ordered;
        this.parm.noAuth = typeof this.parm.noAuth !== 'boolean' ? false : this.parm.noAuth;
        this.parm.authAnonymous = typeof this.parm.authAnonymous !== 'boolean' ? false : this.parm.authAnonymous;
        this.parm.orderingKey = this.parm.orderingKey || null;
        this.parm.attributes = this.parm.attributes || {};

        this.parm.topic = `eeb-${this.parm.name}`
        this.parm.topicSubscription = `eeb-subscription-${this.parm.name}`

        // if (this.parm.noAuth) { this.parm.requireIdEmpresa = false; }

        // Se chamada direta (fora do request, não usa autenticação)
        if (!this.request && !this.response) { this.parm.noAuth = true; }

        if (this.constructor === 'eventBusService') {
            throw new Error("Can't instantiate abstract class eventBusService!");
        }
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

                    const host = helper.getHost(this.request);

                    this.parm = validateResult;
                    this.parm.serviceId = this.parm.serviceId || uuidv4();

                    if (host) {
                        this.parm.host = host;
                    }

                    if (this.parm.noAuth) {
                        return null;
                    } else {
                        const token = helper.getUserTokenFromRequest(this.request, this.response);

                        if (!token) {
                            throw new Error(`Invalid auth`);
                        }

                        return users.getUserInfoWithToken(token);
                    }
                })

                .then(userInfoResult => {

                    if (userInfoResult) {
                        this.parm.attributes.uid = userInfoResult.data.uid;

                        if (userInfoResult.data.isAnonymous && !this.parm.authAnonymous) {
                            throw new Error(`O usuário ${userInfoResult.data.uid} é anonimo e não tem acesso a este endpoint`);
                        }

                        if (
                            !userInfoResult.data.isAnonymous &&
                            !this.parm.authAnonymous &&
                            this.parm.attributes.idEmpresa &&
                            !userInfoResult.data.superUser &&
                            !userInfoResult.data.idsEmpresas.includes(this.parm.attributes.idEmpresa)
                        ) {
                            throw new Error(`O usuário ${userInfoResult.data.uid} não tem acesso à empresa ${this.parm.attributes.idEmpresa}`);
                        }
                    }

                    // Dispara de acordo com o o tipo.
                    if (this.parm.async) { // Async... envia para o Pub/Sub
                        return this._startPublish();
                    } else { // Sync... executa imediatamente
                        return this._startRun();
                    }

                })

                .then(startResult => {
                    result = startResult;
                    result.async = this.parm.async;

                    return resolve(this.response ? this.response.status(200).json(result) : null);
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

            // Se houver idEmpresa em data, adiciona attributes
            if (this.parm.data && this.parm.data.idEmpresa) {
                publishData.attributes.idEmpresa = this.parm.data.idEmpresa;
            }

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
                    result = { result: runResult, code: 200 }

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
            noAuth: Joi.boolean().default(false),
            authAnonymous: Joi.boolean().default(false),
            ordered: Joi.boolean().default(false),
            orderingKey: Joi.string().allow(null)
            // requireIdEmpresa: Joi.boolean().default(true)
        });

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

exports.abstract = eventBusService;

