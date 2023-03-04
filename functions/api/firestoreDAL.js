"use strict";

const admin = require("firebase-admin");
const global = require("../global");
const _ = require("lodash");

class collectionClass {

    constructor(c) {
        this.collectionName = c;
    }

    merge(id, data) {
        return new Promise((resolve, reject) => {
            delete data.id;
            return admin.firestore().collection(this.collectionName).doc(id).set(data, { merge: true })
                .then(_ => {
                    data.id = id;
                    return resolve(data);
                })
                .catch(e => {
                    console.error(e);
                    return reject(e);
                })
        })
    }

    set(id, data, merge) {
        return new Promise((resolve, reject) => {

            let doc;

            delete data.id;

            if (id) {
                doc = admin.firestore().collection(this.collectionName).doc(id);
            } else {
                doc = admin.firestore().collection(this.collectionName).doc();
            }

            delete data.id;

            return doc.set(data, { merge: typeof merge === 'boolean' ? merge : true })
                .then(_ => {
                    data.id = doc.id;
                    return resolve(data);
                })
                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })
    }

    add(data) {
        return new Promise((resolve, reject) => {

            const doc = admin.firestore().collection(this.collectionName).doc();

            delete data.id;
            global.setDateTime(data, 'dtInclusao');

            return doc.set(data)

                .then(_ => {
                    data.id = doc.id;
                    return resolve(data);
                })

                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        })
    }

    delete(id) {
        return new Promise((resolve, reject) => {

            const doc = admin.firestore().collection(this.collectionName).doc(id);

            return doc.delete()
                .then(_ => {
                    return resolve();
                })

                .catch(e => {
                    return reject(e);
                })

        })
    }

    insertUpdate(id, data) {

        global.setDateTime(data, 'dtAlteracao');

        if (id) {
            return this.set(id, data, true);
        } else {
            global.setDateTime(data, 'dtInclusao');
            return this.add(data);
        }
    }

    get(attrs) {
        const self = this;

        if (!this.collection) {
            this.collection = admin.firestore().collection(this.collectionName);
        }

        attrs = attrs || {};

        return new Promise((resolve, reject) => {

            let query = self.collection;

            if (attrs.filter) {
                if (Array.isArray(attrs.filter)) {
                    attrs.filter.forEach(f => {
                        query = query.where(f.field, f.condition || '==', f.value);
                    })
                } else {
                    Object.keys(attrs.filter).forEach(f => {
                        query = query.where(f, '==', attrs.filter[f]);
                    })
                }
            }

            if (attrs.limit) {
                query = query.limit(attrs.limit);
            }

            query.get().then(rows => {
                let result = [];

                rows.forEach(r => {
                    const toPush = Object.assign(r.data(), { id: r.id });
                    delete toPush.keywords;
                    result.push(toPush);
                })

                if (attrs.order) {
                    result = orderArray(result, attrs.order);
                }

                return resolve(result);
            }).catch(e => {
                return reject(new Error(e));
            })
        })
    }

    getReference(id) {
        return admin.firestore().collection(this.collectionName).doc(id);
    }

    getDoc(id, notFoundError) {
        const self = this;

        if (!this.collection) {
            this.collection = admin.firestore().collection(this.collectionName);
        }

        notFoundError = (typeof notFoundError === 'boolean' ? notFoundError : true);

        return new Promise((resolve, reject) => {
            self.collection.doc(id).get().then(doc => {
                if (doc.exists) {
                    return resolve(
                        Object.assign(doc.data(), { id: id })
                    );
                } else {
                    if (notFoundError) {
                        throw new Error(`O documento ${id} não existe na coleção ${self.collectionName}...`);
                    } else {
                        return resolve(null);
                    }
                }
            }).catch(e => {
                return reject(e);
            })
        })
    }

}

const orderArray = (data, order) => {
    if (typeof order === 'string') {
        return _.orderBy(data, [order], ['asc']);
    } else {
        return data;
    }
}

exports.empresas = () => {
    return new collectionClass('empresas');
}

exports.emailBox = () => {
    return new collectionClass('emailBox');
}

exports.emailMessage = () => {
    return new collectionClass('emailMessage');
}

exports._superUsers = () => {
    return new collectionClass('_superUsers');
}

exports._vault = () => {
    return new collectionClass('_vault');
}

exports._webHookReceived = () => {
    return new collectionClass('_webHookReceived');
}

exports.admInterface = () => {
    return new collectionClass('admInterface');
}

exports.admConfigPath = () => {
    return new collectionClass('admConfigPath');
}

exports.admConfigProfiles = () => {
    return new collectionClass('admConfigProfiles');
}

exports.userProfile = () => {
    return new collectionClass('userProfile');
}

exports.cobrancas = () => {
    return new collectionClass('cobrancas');
}

exports.apiConfig = () => {
    return new collectionClass('apiConfig');
}

exports.log = () => {
    return new collectionClass('_log');
}

exports.serviceUserCredential = () => {
    return new collectionClass('serviceUserCredential');
}

exports.appUsers = () => {
    return new collectionClass('appUsers');
}

exports.serviceError = () => {
    return new collectionClass('_serviceError');
}

exports.serviceUserCredential = () => {
    return new collectionClass('serviceUserCredential');
}

exports.deadLettering = _ => {
    return new collectionClass('_eebDeadLettering');
}

exports.eebTest = _ => {
    return new collectionClass('_eebTest');
}

exports.frontTemplates = _ => {
    return new collectionClass('frontTemplates');
}

exports.influencers = _ => {
    return new collectionClass('empresas');
}

exports.campanhas = _ => {
    return new collectionClass('campanhas');
}

exports.fcmTokens = _ => {
    return new collectionClass('fcmTokens');
}

exports.campanhasInfluencers = _ => {
    return new collectionClass('campanhasInfluencers');
}

exports.campanhasSorteios = _ => {
    return new collectionClass('campanhasSorteios');
}

exports.campanhasSorteiosPremios = _ => {
    return new collectionClass('campanhasSorteiosPremios');
}

exports.appLinks = _ => {
    return new collectionClass('appLinks');
}

exports.titulos = _ => {
    return new collectionClass('titulos');
}

exports.titulosPremios = _ => {
    return new collectionClass('titulosPremios');
}

exports.titulosCompras = _ => {
    return new collectionClass('titulosCompras');
}

exports.faq = _ => {
    return new collectionClass('faq');
}

exports.cartosAccounts = _ => {
    return new collectionClass('cartosAccounts');
}

exports.cartosPixKeys = _ => {
    return new collectionClass('cartosPixKeys');
}

exports.cartosPixPreGenerated = _ =>{
    return new collectionClass('cartosPixPreGenerated');
}

exports.cartosBalance = _ => {
    return new collectionClass('cartosBalance');
}

exports.cartosExtract = _ => {
    return new collectionClass('cartosExtract');
}

exports.cartosPix = _ => {
    return new collectionClass('cartosPix');
}

exports.cartosPixPago = _ => {
    return new collectionClass('cartosPixPago');
}
