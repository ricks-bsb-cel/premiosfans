"use strict";

const helper = require('./eventBusServiceHelper');

const taskReceiver = (request, response) => {

    if (!request.body) return response.status(500).json({ error: "Invalid payload." });

    const payload = JSON.parse(request.body);

    const data = payload.data || null;
    const attributes = payload.attributes || null;

    if (!data || !attributes) return response.status(500).json({ error: "Invalid payload." });

    delete data.delay;

    const parm = {
        async: false,
        debug: false,
        data: data,
        attributes: attributes,
        serviceId: attributes.serviceId,
        method: attributes.method,
        topic: 'eeb-' + attributes.method,
        source: 'task'
    };

    helper.log('task-run-init', helper.logType.info, {
        method: parm.method,
        serviceId: parm.serviceId
    });

    const req = require(`./services/${parm.method}`);
    const service = new req.Service(null, null, parm);

    return service.run()

        .then(_ => {
            helper.log('task-run-success', helper.logType.info, {
                method: parm.method,
                serviceId: parm.serviceId
            });

            return response.status(200).end();
        })

        .catch(e => {
            console.error(e);

            helper.log('task-run-error', helper.logType.error, {
                method: parm.method,
                serviceId: parm.serviceId,
                error: e.toString()
            });

            return response.status(500).end();
        })

}

exports.taskReceiver = taskReceiver;
