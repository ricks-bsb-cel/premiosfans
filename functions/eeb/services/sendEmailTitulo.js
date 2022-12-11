"use strict";

const path = require('path');
const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const sendGridKey = "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";
const templateId = "d-87d6aef6ec6147a59481030d3018f61a";

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const buTitulo = require('../../business/titulo');

const schema = _ => {
    const schema = Joi.object({
        idTitulo: Joi.string().token().min(18).max(22).required(),
        showDataOnly: Joi.boolean().default(false).optional()
    });

    return schema;
}


class Service extends eebService {

    constructor(request, response, parm) {
        const method = path.basename(__filename, '.js');

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                host: this.parm.host
            };

            return schema().validateAsync(this.parm.data)
                .then(dataResult => {
                    result.data = dataResult;

                    return buTitulo.getById(result.data.idTitulo)
                })

                .then(buTituloResult => {
                    result.titulo = buTituloResult;
                    result.email = buTituloResult.email;

                    if (result.data.showDataOnly) {
                        return {
                            message: "ignored"
                        };
                    }

                    const sgMail = require('@sendgrid/mail');

                    sgMail.setApiKey(sendGridKey);

                    const parm = {
                        from: {
                            email: 'nao-responda@premios.fans',
                            name: 'Premios.Fans'
                        },
                        personalizations: [{
                            to: [
                                {
                                    email: buTituloResult.email,
                                    name: buTituloResult.nome
                                }
                            ],
                            dynamic_template_data: buTituloResult
                        }],
                        subject: 'Seus Números da Sorte ~ Certificado ' + buTituloResult.id,
                        template_id: templateId
                    };

                    return sgMail.send(parm);
                })

                .then(sendResult => {
                    result.sendResult = sendResult;

                    return resolve(this.parm.async ? { success: true, email: result.email } : result);
                })

                .catch(e => {
                    console.error(e);

                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

const call = (data, request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const parm = {
        name: 'send-email-titulo',
        async: request && request.query.async ? request.query.async === 'true' : true,
        debug: request && request.query.debug ? request.query.debug === 'true' : false,
        auth: eebAuthTypes.internal,
        data: data
    }

    if (data.delay) {
        parm.delay = data.delay;
        delete data.delay;
    }

    const service = new Service(request, response, parm);

    return service.init();
}

exports.call = call;

exports.callRequest = (request, response) => {
    return call(request.body, request, response);
}
