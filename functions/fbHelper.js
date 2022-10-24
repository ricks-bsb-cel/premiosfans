const admin = require("firebase-admin");

const toDoc = value => {
    if (!value) { return null; }

    try {   
        if (!value.exists) {
            return null;
        }
        return Object.assign(value.data(), { id: value.id });
    } catch (e) {
        console.info('fbHelper toDoc unknow class');
        return null;
    }
}

exports.toDoc = value => { return toDoc(value); }

exports.toDocArray = value => {
    if (!value) { return null; }

    if (!Array.isArray(value)) { throw new Error('Valor não é uma array...'); }

    var result = [];

    value.forEach(v => {
        result.push(toDoc(v));
    })

    return result;
}

exports.toList = value => {

    if (!value) {
        return null;
    }

    try {
        if (value.empty) {
            return [];
        }

        var result = [];

        value.forEach(v => {
            result.push(Object.assign(v.data(), { id: v.id }));
        })

        return result;
    } catch (e) {
        console.info('fbHelper toList: value is not a QuerySnapshot');
        return null;
    }
}

