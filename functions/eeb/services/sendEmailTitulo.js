"use strict";

const eebService = require('../eventBusService').abstract;
const Joi = require('joi');

const sendGridKey = "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";
const templateId = "d-87d6aef6ec6147a59481030d3018f61a";

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
https://github.com/googleapis/nodejs-storage/blob/main/samples/listFiles.js
*/

const firestoreDAL = require('../../api/firestoreDAL');
const collectionTitulosCompra = firestoreDAL.titulosCompras();

const buTitulo = require('../../business/titulo');
const acompanhamentoTituloCompra = require('./acompanhamentoTituloCompra');

const schema = _ => {
    const schema = Joi.object({
        idTitulo: Joi.string().token().min(18).max(22).required(),
        showDataOnly: Joi.boolean().default(false).optional()
    });

    return schema;
}


class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    async run() {

        const result = {
            success: true,
            host: this.parm.host
        };

        result.data = await schema().validateAsync(this.parm.data);
        result.titulo = await buTitulo.getById(result.data.idTitulo);

        result.email = result.titulo.email;

        result.tituloCompra = await collectionTitulosCompra.getDoc(result.titulo.idTituloCompra);

        if (result.data.showDataOnly) return (this.parm.async ? { success: true, email: result.email } : result);

        // Envio do Email via Sendgrid
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
                        email: result.titulo.email,
                        name: result.titulo.nome
                    }
                ],
                dynamic_template_data: result.titulo,
                subject: '%F0%9F%92%B0 Seus Números da Sorte ~ Certificado ' + result.titulo.idTitulo,
                substitutions: {
                    subject: '%F0%9F%92%B0 Seus Números da Sorte ~ Certificado ' + result.titulo.idTitulo
                }
            }],
            template_id: templateId
        };

        const sendResult = await sgMail.send(parm);

        sendResult.forEach(s => {
            if (s) {
                acompanhamentoTituloCompra.setEmailEnviado(
                    result.tituloCompra,
                    result.titulo.idTitulo,
                    {
                        payload: parm,
                        result: s.headers
                    }
                );
            }
        })

        return (this.parm.async ? { success: true, email: result.email } : sendResult);

    }
    /*
    run() {
        return new Promise((resolve, reject) => {

            const result = {
                success: true,
                host: this.parm.host
            };

            let parm;

            return schema().validateAsync(this.parm.data)
                .then(dataResult => {
                    result.data = dataResult;

                    return buTitulo.getById(result.data.idTitulo)
                })

                .then(buTituloResult => {
                    result.titulo = buTituloResult;
                    result.email = buTituloResult.email;
                    result.buTitulo = buTituloResult;

                    return collectionTitulosCompra.getDoc(result.titulo.idTituloCompra);
                })

                .then(tituloCompra => {
                    result.tituloCompra = tituloCompra;

                    if (result.data.showDataOnly) return { message: "ignored" };

                    const sgMail = require('@sendgrid/mail');

                    sgMail.setApiKey(sendGridKey);

                    parm = {
                        from: {
                            email: 'nao-responda@premios.fans',
                            name: 'Premios.Fans'
                        },
                        personalizations: [{
                            to: [
                                {
                                    email: result.buTitulo.email,
                                    name: result.buTitulo.nome
                                }
                            ],
                            dynamic_template_data: result.titulo,
                            subject: '%F0%9F%92%B0 Seus Números da Sorte ~ Certificado ' + result.titulo.idTitulo,
                            substitutions: {
                                subject: '%F0%9F%92%B0 Seus Números da Sorte ~ Certificado ' + result.titulo.idTitulo
                            }
                        }],
                        template_id: templateId
                    };

                    return sgMail.send(parm);
                })

                .then(sendResult => {
                    result.sendResult = sendResult;

                    sendResult.forEach(s => {
                        if (s) {
                            return acompanhamentoTituloCompra.setEmailEnviado(
                                result.tituloCompra,
                                result.titulo.idTitulo,
                                {
                                    payload: parm,
                                    result: s.headers
                                }
                            );
                        }
                    })

                })

                .then(_ => {
                    return resolve(this.parm.async ? { success: true, email: result.email } : result);
                })

                .catch(e => {
                    console.error(e);

                    return reject(e);
                })

        })
    }
    */

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
