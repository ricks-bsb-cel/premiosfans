const admin = require("firebase-admin");

const toDoc = value => {
    if (!value) { return null; }

    if (value instanceof admin.firestore.QueryDocumentSnapshot) { // Firestore Snapshot
        if (!value.exists) {
            return null;
        }
        return Object.assign(value.data(), { id: value.id });
    } else {
        console.info('fbHelper toDoc unknow class:', value.constructor.name);
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

    if (value instanceof admin.firestore.QuerySnapshot) { // Firestore Snapshot

        if (value.empty) {
            return [];
        }

        var result = [];

        value.forEach(v => {
            result.push(Object.assign(v.data(), { id: v.id }));
        })

        return result;
    } else {
        console.info('fbHelper toList unknow class:', value.constructor.name);
        return null;
    }
}

