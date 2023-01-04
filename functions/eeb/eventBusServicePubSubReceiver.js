"use strict";

const helper = require('./eventBusServiceHelper');
const audit = require('./eventBusServiceAudit');

const pubSubReceiver = (request, response) => {

    if (!request.body || !request.body.message) {
        return response.status(500).json({
            error: "Invalid payload."
        });
    }

    const
        data = helper.base64ToJson(request.body.message.data) || {},
        attributes = request.body.message.attributes;

    let msgAlreadyProcessed = false;

    const parm = {
        async: false,
        debug: false,
        data: data,
        attributes: attributes,
        serviceId: attributes.serviceId,
        method: attributes.method,
        messageId: request.body.message.messageId,
        source: 'pub-sub'
    };

    return audit.auditMessageIdExists(parm.messageId)

        .then(eventMessageExistsResult => {
            msgAlreadyProcessed = eventMessageExistsResult;

            if (msgAlreadyProcessed) {
                helper.log('async-run-already-processed', helper.logType.info, { messageId: parm.messageId });
                return null;
            }

            return audit.startAuditMessageId(parm.messageId);
        })

        .then(_ => {
            if (msgAlreadyProcessed) { return null; }

            helper.log('async-run-init', helper.logType.info, { method: parm.method, serviceId: parm.serviceId });

            const req = require(`./${attributes.method}`);
            const service = new req.Service(null, null, parm);

            return service.run();
        })

        .then(_ => {
            if (!msgAlreadyProcessed) {
                helper.log('async-run-success', helper.logType.info, {
                    method: parm.method,
                    serviceId: parm.serviceId
                });

                return audit.endAuditMessageId(parm.messageId);
            } else {
                return null;
            }
        })

        .then(_ => {
            return response.status(200).end();
        })

        .catch(e => {
            helper.log('async-run-error', helper.logType.error, {
                method: parm.method,
                serviceId: parm.serviceId,
                error: e.toString()
            });

            return response.status(500).end();
        })

}

exports.pubSubReceiver = pubSubReceiver;
