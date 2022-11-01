"use strict";

const helper = require('./eventBusServiceHelper');

const firestoreDAL = require('../api/firestoreDAL');
const collectionDeadLettering = firestoreDAL.deadLettering();

const pubSubDeadLetterReceiver = (request, response) => {

    try {

        if (!request.body || !request.body.message) {
            return response.status(500).json({
                error: "Invalid payload."
            });
        }

        const data = helper.base64ToJson(request.body.message.data) || {},
            attributes = request.body.message.attributes,
            parm = {
                data: data,
                attributes: attributes,
                serviceId: attributes.serviceId,
                method: attributes.method
            };

        return collectionDeadLettering.add(parm)
            .then(_ => {
                return response.status(200).end();
            })
            .catch(e => {
                return response.status(500).end();
            })

    }

    catch (e) {
        return response.status(e.code || 500).send(e);
    }

}

exports.pubSubDeadLetterReceiver = pubSubDeadLetterReceiver;
