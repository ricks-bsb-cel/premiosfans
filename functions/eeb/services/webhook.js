"use strict";

const eebService = require('../eventBusService').abstract;

const firestoreDAL = require('../../api/firestoreDAL');
const collectionWebHook = firestoreDAL._webHookReceived();

const bigQueryAddRow = require('./bigquery/bigqueryAddRow');

async function exportPixInToBigQuery(payload) {

    if (!payload.data || payload.data.event !== 'transaction.PixIn') {
        return;
    }

    const paymentData = payload.data.data.data;

    const data = {
        accountId: paymentData.accountId,
        accountAgency: paymentData.account.agency,
        accountBankId: paymentData.account.bankId,
        accountCompanyName: paymentData.account.companyName,
        accountDocumentNumber: paymentData.account.documentNumber,
        accountEmail: paymentData.account.email,
        accountNumber: paymentData.account.number,
        accountPersonType: paymentData.account.personType,
        accountType: paymentData.account.type,

        amount: parseFloat((parseInt(paymentData.amount) / 100).toFixed(2)),
        category: paymentData.category,

        payerAccount: paymentData.transactionData.accountPayer,
        payerAccountType: paymentData.transactionData.accountTypePayer,
        payerAgency: paymentData.transactionData.agencyPayer,
        payerBankIspb: paymentData.transactionData.bankIspbPayer,
        payerName: paymentData.transactionData.clientNamePayer,
        payerDocument: paymentData.transactionData.documentPayer,

        operationNumber: paymentData.transactionData.operationNumber,
        transactionId: paymentData.transactionId,
        txId: paymentData.transactionData.txId,

        createdAt: paymentData.createdAt,
        updatedAt: paymentData.updatedAt
    }

    const bigQueryParm = {
        "tableType": "bigQueryTablePixIn",
        "datasetId": "global",
        "tableName": "PixIn",
        "row": data
    };

    bigQueryAddRow.call(bigQueryParm);
}

class Service extends eebService {

    constructor(request, response, parm) {
        const method = eebService.getMethod(__filename);

        super(request, response, parm, method);
    }

    run() {
        return new Promise((resolve, reject) => {

            const toAdd = {
                data: this.parm.data,
                attributes: this.parm.attributes,
                method: this.parm.method,
                serviceId: this.parm.serviceId
            };

            return collectionWebHook.add(toAdd)

                .then(addResult => {
                    toAdd.id = addResult.id;

                    return exportPixInToBigQuery(toAdd);
                })

                .then(_ => {
                    return resolve(toAdd)
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

}

exports.Service = Service;

exports.callRequest = (request, response) => {
    const eebAuthTypes = require('../eventBusService').authType;

    const parm = {
        name: 'webhook',
        async: request.query.async ? request.query.async === 'true' : true,
        debug: request.query.debug ? request.query.debug === 'true' : false,
        data: request.body || {},
        auth: eebAuthTypes.noAuth,
        attributes: {
            source: request.params.source
        }
    };

    if (request.params.type) {
        parm.attributes.type = request.params.type;
    }

    const service = new Service(request, response, parm);

    return service.init();
}
