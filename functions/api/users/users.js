"use strict";

const admin = require("firebase-admin");
const { Timestamp } = require('firebase-admin/firestore');

const moment = require("moment-timezone");
const secret = require('../../secretManager');
const jwt = require('jsonwebtoken');
const _ = require("lodash");

const { getAuth } = require("firebase-admin/auth");

const firestoreDAL = require("../firestoreDAL");
const global = require('../../global');
const fbHelper = require('../../fbHelper');

const collectionEmpresas = firestoreDAL.empresas();
const collectionUserProfile = firestoreDAL.userProfile();
const collectionConfigProfiles = firestoreDAL.admConfigProfiles();
const collectionConfigPath = firestoreDAL.admConfigPath();

const idSuperUser = 'RaxbGarlPwgSeM64PKr0lpMBlHb2';

exports.idSuperUser = idSuperUser;

/* https://firebase.google.com/docs/auth/admin/custom-claims */

exports.requestUserInfo = (request, response) => {

    const token = global.getUserTokenFromRequest(request, response);
    const full = request.query.full === 'true';
    let uid = request.params.uid || null;

    if (uid && uid.toLowerCase() === 'current') { uid = null; }

    if (!token) {
        return response.status(500).json(
            global.defaultResult({ code: 500, error: 'token not found' }, true)
        );
    }

    return getUserInfoWithToken(token, full, uid)

        .then(result => {

            result.headers = request.headers;
            result.extrainfo = result.extrainfo || {};

            if (!uid) {
                result.extrainfo.source = result.tokenSource;
            }

            delete result.extrainfo.uid;
            delete result.extrainfo.email;
            delete result.extrainfo.displayName;
            delete result.extrainfo.idEmpresa;
            delete result.extrainfo.superUser;

            if (!result.data.superUser) delete result.data.superUser;

            return response.status(200).json(
                global.defaultResult(result, true)
            );

        })

        .catch(e => {
            console.error(e);

            return response.status(e.code || 500).json(global.defaultResult({ code: e.code, error: e.message }, true));
        })

};


exports.requestSetSuperUser = (request, response) => {

    const token = global.getUserTokenFromRequest(request, response);
    const uid = request.params.uid;
    const idConfigProfile = request.body.idConfigProfile || request.body.idProfile || null;

    if (!token || !uid) {
        return response.status(500).json(
            global.defaultResult({ code: 500, error: 'invalid request' }, true)
        );
    }

    let result = {}, customClaims;

    return getUserInfoWithToken(token)

        .then(currentUser => {
            result.currentUser = currentUser;

            if (!result.currentUser.data.superUser) throw new Error('Apenas super usuários podem conceder acessos para outros');

            return admin.auth().getUser(uid);
        })

        .then(resultUserInfo => {
            result.userToChange = resultUserInfo;

            if (result.userToChange.providerData.length !== 1) throw new Error('Super usuários só podem ter um provedor de conexão');
            if (result.userToChange.providerData[0].providerId !== 'google.com') throw new Error('O provedor de conexão de super usuários tem que ser google.com');

            customClaims = result.userToChange.customClaims || {};

            customClaims.superUser = true;

            if (idConfigProfile) {
                customClaims.idConfigProfile = idConfigProfile;
            } else {
                delete customClaims.idConfigProfile;
            }

            return admin.auth().setCustomUserClaims(uid, customClaims);
        })

        .then(_ => {
            result = { success: true };

            return response.status(200).json(
                global.defaultResult({ data: customClaims }, true)
            );
        })

        .catch(e => {
            console.error(e);

            return response.status(500).json(global.defaultResult({ error: e.message }, true));
        })

};

const toUserProfile = doc => {

    const result = {
        id: doc.id,
        idEmpresa: doc.idEmpresa,
        // Dados recebidos
        doc: {
            uid: doc.id,
            nome: doc.displayName || null,
            email: doc.email || null,
            celular: doc.phoneNumber || null,
            imagem: doc.photoURL || null,
            ativo: doc.ativo
        },
        // Ações possíveis
        actions: [
        ],
        // extendeds...
        extend: {
            usuario: `/api/users/v1/user/${doc.id}`
        }
    }

    if (doc.dtInclusao) {
        result.extrainfo = {
            dtInclusao: moment(doc.dtInclusao.toDate()).format('YYYY-MM-DD HH:mm:ss.SSS')
        }
    }
    return result;
};


const getUserInfoWithToken = (token, full, uid) => {
    return new Promise((resolve, reject) => {

        // Tenta resolver o token das duas formas... uma vai dar certo
        let user,
            userRecord,
            result = {};

        const checkToken = [
            resolveFirebaseToken(token),
            resolveJwtToken(token)
        ]

        Promise.all(checkToken)


            .then(solutions => {

                user = solutions[0] || solutions[1];

                if (!user) {
                    throw global.newError(`Invalid or expired token: ${token}`, 401);
                }

                return getAuth().getUser(user.data.uid);
            })

            .then(getUserResult => {

                userRecord = getUserResult;

                const isPhoneProvider = (userRecord.providerData || []).findIndex(f => {
                    return f.providerId === 'phone';
                }) >= 0;

                if (!user.data.idEmpresa && !user.data.superUser && !isPhoneProvider) {

                    let userDetail = user.data.uid;

                    if (userRecord.phoneNumber) { userDetail += ', ' + userRecord.phoneNumber; }
                    if (userRecord.email) { userDetail += ', ' + userRecord.email; }

                    throw new Error(`O usuário atual [${userDetail}] não pertence a nenhuma empresa`);
                }

                if (userRecord.customClaims) user.data.customClaims = userRecord.customClaims;

                // Carrega as empresas do token do usuário atual
                return admin.database().ref(`/usuario/${user.data.uid}/user/empresas`).once("value");
            })

            .then(empresasUsuarioAtual => {

                user.data.idsEmpresas = getIdsEmpresas(empresasUsuarioAtual);

                if (uid) {
                    // Solicitada informações de outro usuário...
                    return getUserInfo(uid);
                } else {
                    // Solicitada informações do usuário do próprio token...
                    if (full) {
                        return getUserInfo(user.data.uid);
                    } else {
                        return null;
                    }
                }

            })

            .then(userInfo => {

                if (uid) {

                    // Solicitada informações de outro usuário...
                    if (user.data.idEmpresa !== userInfo.idEmpresa && !user.data.superUser) {
                        throw new Error('O acesso atual não pode pesquisar usuários de outra empresa');
                    }

                    result.data = {
                        uid: userInfo.uid,
                        email: userInfo.email,
                        displayName: userInfo.displayName || userRecord.displayName,
                        idEmpresa: userInfo.idEmpresa || null,
                        superUser: userInfo.superUser || false,
                        idsEmpresas: getIdsEmpresas(userInfo.empresas),
                        customClaims: userRecord.customClaims,
                        providers: []
                    }

                    result.extrainfo = {
                        source: user.tokenSource
                    }

                } else {

                    // Solicitada informações do usuário do próprio token...
                    result = user;

                    result.data.displayName = result.data.displayName || userRecord.displayName || null;
                    result.data.email = result.data.email || userRecord.email || null;
                    result.data.providers = [];

                    if (userRecord.phoneNumber) {
                        result.data.phoneNumber = userRecord.phoneNumber;
                    }

                }

                if (full) {
                    result.extrainfo = Object.assign(result.extrainfo || {}, userInfo);
                }

                (userRecord.providerData || []).forEach(m => {
                    result.data.providers.push(m.providerId);
                })

                if (result.data.providers.length === 1 && result.data.providers[0] === 'phone') {

                    delete result.data.superUser;
                    delete result.data.idsEmpresas;
                    delete result.data.providers;

                    return admin.database().ref(`/app/${result.data.uid}/profile`).once("value");
                } else {
                    return null;
                }

            })

            .then(profile => {

                profile = profile ? profile.val() : null;

                if (profile) {
                    if (!result.data.displayName) { result.data.displayName = profile.displayName || null; }
                    if (!result.data.email) { result.data.email = profile.email || null; }
                }

                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}


const resolveJwtToken = token => {
    return new Promise(resolve => {

        const result = {};

        return secret.get('api-default-certificate-public-key')

            .then(certificate => {

                try {

                    const user = jwt.verify(token, certificate.public_key);

                    result.data = {
                        uid: user.uid,
                        email: user.email,
                        displayName: user.displayName,
                        idEmpresa: user.idEmpresa,
                        superUser: user.superUser || false
                    }

                    if (result.data.uid === idSuperUser) result.data.superUser = true;

                    result.tokenSource = 'premiosfansapi';

                    return resolve(result);

                }

                catch (e) {
                    throw new Error(e);
                }

            })

            .catch(e => {
                return resolve(null);
            })

    })
}


const resolveFirebaseToken = token => {
    return new Promise(resolve => {

        const result = {};

        return admin.auth().verifyIdToken(token)
            .then(user => {

                result.data = {
                    uid: user.uid,
                    email: user.email,
                    displayName: user.name,
                    idEmpresa: user.idEmpresa,
                    superUser: user.superUser || false
                };

                result.tokenSource = 'firebase';

                if (result.data.uid === idSuperUser) result.data.superUser = true;

                return resolve(result);
            })
            .catch(e => {
                return resolve(null);
            })

    })
}


const getIdsEmpresas = empresas => {
    if (!Array.isArray(empresas)) empresas = empresas.val();

    const result = [];

    if (empresas) {
        empresas.forEach(e => {
            result.push(e.id);
        })
    }
    return result;
}


exports.requestGetProfiles = (request, response) => {
    const token = global.getUserTokenFromRequest(request, response);

    let Usuario = null;

    if (!token) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'empty token'
        }));
    }

    return global.verifyTokenFromRequest(request)

        .then(user => {

            Usuario = user;

            if (!Usuario.idEmpresa && !Usuario.superUser) {
                throw new Error('O usuário atual não está vinculado a uma empresa')
            }

            let collection = admin.firestore().collection('userProfile');

            if (!Usuario.superUser) {
                collection = collection.where('idsEmpresa', 'array-contains', Usuario.idEmpresa);
            }

            return collection.get();

        })

        .then(data => {

            const result = {},
                rows = [];

            data.forEach(d => {
                rows.push(toUserProfile(Object.assign(d.data(), { id: d.id })));
            })

            result.rows = rows;

            if (!Usuario.superUser) {
                result.idEmpresa = Usuario.idEmpresa
            }

            return response.status(200).json(
                global.defaultResult(result, Usuario.superAdm)
            );

        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({
                    code: e.code || 500,
                    error: e.message
                })
            );
        })

};


exports.setEmpresaToUser = (request, response) => {
    // Seleciona uma empresa no token do usuário
    // A empresa já deve estar cadastrada no userProfile do usuário

    const token = global.getUserTokenFromRequest(request, response);
    const uid = request.body.uid || null;
    const idEmpresa = request.body.idEmpresa || null;

    let userToken = null,
        user = null,
        empresa = null;

    if (!token || !uid || !idEmpresa) {
        return response.status(500).json(
            global.defaultResult({
                error: 'Parâmetros inválidos...'
            })
        )
    }

    return getUserInfoWithToken(token)

        .then(resultUserToken => {
            userToken = resultUserToken.data;

            // retorna os dados do usuário que se deseja alterar
            return getUserInfo(uid);
        })

        .then(userData => {
            user = userData;

            // Se o token não for do mesmo usuário, tem que ser token de superAdm
            if (userToken.uid !== uid && !userToken.superUser) {
                throw new Error(`O usuário atual ${userToken.email} não tem permissão para selecionar a empresa do usuário ${user.email}. No momento apenas superUsuários podem executar este procedimento.`);
            }

            // Verifica se a empresa existe
            return collectionEmpresas.getDoc(idEmpresa, false);
        })

        .then(resultEmpresa => {

            if (!resultEmpresa) {
                throw new Error(`Não existe nenhuma empresa com o identificador ${idEmpresa}.`);
            }

            if (!resultEmpresa.ativo) {
                throw new Error(`A empresa ${resultEmpresa.nome} não está ativa.`);
            }

            empresa = resultEmpresa;

            // Verifica se o usuário pode utilizar a empresa
            return admin.firestore()
                .collection('userProfile').doc(uid)
                .collection('empresas').doc(idEmpresa)
                .get();
        })

        .then(userProfileEmpresa => {

            if (!user.superUser && !userProfileEmpresa.exists) {
                throw new Error(`A empresa [${empresa.nome}] não está cadastrada no perfil do usuário.`);
            }

            const customClaims = user.customClaims || {};

            delete customClaims.idEmpresas
            customClaims.idEmpresa = idEmpresa;

            if (user.superUser) {
                customClaims.superUser = true;
            }

            // Adiciona os dados da empresa no CustomClaims do usúario Firebase
            return setCustomUserClaims(uid, customClaims);

        })

        .then(_ => {
            // Atualiza o id da empresa Selecionada no Profile
            return collectionUserProfile.merge(uid, {
                idEmpresaAtual: idEmpresa,
                empresaAtual: empresa.nome
            });
        })

        .then(_ => {
            return getUserInfo(uid);
        })

        .then(userData => {
            return response.json(global.defaultResult({ data: userData }, true));
        })

        .catch(e => {
            console.error(e);

            return response.status(e.code || 500).json(global.defaultResult({
                code: e.code,
                error: e.message
            }));
        })

};


exports.setSuperUser = (request, response, setSuperUser) => {

    const token = global.getUserTokenFromRequest(request, response);
    const uid = request.body.uid || null;

    let defaultErrorCode = 500;

    if (!token || !uid) {
        return response.status(500).json(
            global.defaultResult({
                code: 500,
                error: "Invalid parms..."
            })
        );
    }

    return admin
        .auth()
        .verifyIdToken(token)

        .then(userToken => {
            return admin.auth().getUser(userToken.uid);
        })

        .then(user => {
            if (!(user.customClaims || {}).superUser && uid !== "hZk3aMVkYqPhHLrnDro5Sln8Py32") {
                throw new Error(`O usuário atual [${user.email}] não é superUser e não pode aplicar esta regra para outros usuários...`);
            }

            // Impede que algum engraçadinho revogue a minha autorização (ricks.bsb.cel@gmail.com)
            if (!setSuperUser && uid === "hZk3aMVkYqPhHLrnDro5Sln8Py32") {
                defaultErrorCode = 418; // https://developer.mozilla.org/pt-BR/docs/Web/HTTP/Status/418
                throw new Error(`You have no power here...`);
            }

            return admin.auth().getUser(uid);
        })

        .then(user => {
            const customClaims = user.customClaims || {};

            if (setSuperUser) {
                customClaims.superUser = setSuperUser;
            } else {
                delete customClaims.superUser;
            }

            return setCustomUserClaims(uid, customClaims);
        })

        .then(_ => {
            return getUserInfo(uid);
        })

        .then(userData => {
            return response.json(
                global.defaultResult({ data: userData })
            );
        })

        .catch(e => {
            return response.status(defaultErrorCode).json(
                global.defaultResult({
                    code: defaultErrorCode,
                    error: e.message
                })
            );
        })

};


exports.getUsers = (request, response) => {

    const token = global.getUserTokenFromRequest(request, response);

    let query = admin.firestore().collection('userProfile');

    if (!token) {
        return response.status(500).json(
            global.defaultResult({
                error: 'invalid token'
            })
        )
    }

    return getUserInfoWithToken(token)

        .then(user => {
            if (!user.data.idEmpresa) {
                throw new Error('Usuário atual não vinculado a nenhuma empresa')
            }

            query = query.where('idsEmpresas', 'array-contains', user.data.idEmpresa);

            return query.get();
        })

        .then(docs => {
            const rows = [];

            docs.forEach(d => {
                d = Object.assign(d.data(), { id: d.id });

                rows.push(toUserProfile(d));
            });

            return response.json(
                global.defaultResult({
                    rows: rows
                }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(global.defaultResult({
                code: e.code,
                error: e.message
            }));
        })

}


exports.updateUser = (request, response) => {

    const token = request.headers.token || null;
    const uid = request.body.uid || null;
    const idEmpresas = request.body.idEmpresas || [];
    const nome = request.body.nome || null;

    if (!token || !uid) {
        return response.status(500).json({ error: 'parm error' });
    }

    return admin.auth().verifyIdToken(token)

        .then(_ => {
            return getUserInfo(uid);
        })

        .then(userToUpdate => {
            const customClaims = userToUpdate.customClaims || {};
            customClaims.idEmpresas = idEmpresas;
            return setCustomUserClaims(uid, customClaims);
        })

        .then(success => {
            return updateUserData(uid, { displayName: nome });
        })

        .then(success => {
            return getUserInfo(uid);
        })

        .then(userData => {
            return response.json(formatUserObj(userData));
        })

        .catch(e => {
            return response.status(e.code || 500).json({ error: e.message });
        })

}


exports.checkUserProfile = (request, response) => {

    // Verifica se o Profile do usuário já existe em userProfile e o adiciona se não existir. Não cria o Perfil de acesso...
    return new Promise((resolve, reject) => {

        const Cookies = require("cookies");
        const cookies = new Cookies(request, response);
        const userToken = cookies.get("__session") || request.body.__session || null;

        let user, userProfile;

        if (!userToken) return resolve(null);

        return admin.auth().verifyIdToken(userToken)
            .then(resultVerifyIdToken => {
                if (!resultVerifyIdToken) return resolve(null);

                user = resultVerifyIdToken;

                return collectionUserProfile.getDoc(user.uid, false);
            })

            .then(resultUserProfile => {

                userProfile = resultUserProfile || {};

                userProfile.disabled = user.disabled || false;
                userProfile.displayName = user.name || null;
                userProfile.dtAlteracao = Timestamp.now();
                userProfile.email = user.email || null;
                userProfile.emailVerified = typeof user.email_verified === 'boolean' ? user.email_verified : false;
                userProfile.photoURL = user.picture || null;
                userProfile.keywords = global.generateKeywords(userProfile.displayName, userProfile.email);

                if (typeof userProfile.uid === 'undefined') userProfile.uid = user.uid;
                if (typeof userProfile.ativo !== 'boolean') userProfile.ativo = false;

                return collectionUserProfile.collection.doc(user.uid).set(userProfile, { merge: true });
            })

            .then(_ => {
                return resolve(userProfile)
            })

            .catch(e => {
                if (e.code === 'auth/id-token-expired') {
                    return resolve(null)
                } else {
                    console.error(e.code, e);

                    return reject(e);
                }
            })

    })
}


const getUserProfile = uid => {
    return new Promise((resolve, reject) => {

        const result = {
            user: null,
            perfil: null,
            dtReference: Timestamp.now(),
            version: global.getVersionId()
        };

        const promissesPerfis = [];

        return getUserInfo(uid)

            .then(userResult => {

                result.user = userResult;

                if (result.user.uid === idSuperUser) result.user.superUser = true;

                const userId = result.user.email || global.getFormatPhoneNumber(result.user.phoneNumber);

                if (!result.user.empresas || result.user.empresas.length === 0 && !result.user.superUser) {
                    throw new Error(`O usuário ${userId} não tem perfil em nenhuma empresa.`);
                }

                if (!result.user.idEmpresa && !result.user.superUser) {
                    throw new Error(`O usuário ${userId} não está habilitado para nenhuma empresa.`);
                }

                // Verifica o perfil que o usuário deve utilizar
                const i = result.user.empresas.findIndex(f => {
                    return f.id === result.user.idEmpresa;
                })

                // Se o usuário está vinculado à alguma empresa, mas não foi selecionado em nenhuma
                if (i < 0 && !result.user.superUser) {
                    throw new Error(`O usuario não está vinculado a nenhuma empresa.`);
                }

                if (result.user.superUser && i < 0) {
                    // Erro no perfil. Se superUser abre do SuperUser
                    return collectionConfigProfiles.getDoc(result.user.customClaims.idConfigProfile || 'bIOIFnaGz7CYUsS1WA9P');
                } else {
                    return collectionConfigProfiles.getDoc(result.user.empresas[i].idPerfil);
                }

            })

            .then(perfil => {
                result.perfil = perfil || null;

                if (result.perfil) {
                    result.perfil.dtAlteracao = global.asDate(result.perfil.dtAlteracao);
                    result.perfil.dtInclusao = global.asDate(result.perfil.dtInclusao);

                    delete result.perfil.idUser;
                    delete result.perfil.collections;

                    result.perfil.groups.forEach(g => {
                        g.options.forEach(o => {
                            promissesPerfis.push(collectionConfigPath.getDoc(o.id));
                        })
                    })
                }

                return Promise.all(promissesPerfis);
            })

            .then(resultPromissesPerfis => {

                if (result.perfil) {
                    result.perfil.groups.forEach(g => {
                        g.options.forEach(o => {
                            const i = resultPromissesPerfis.findIndex(f => { return f.id === o.id; });

                            if (i >= 0) {
                                o = Object.assign(o, {
                                    href: resultPromissesPerfis[i].href,
                                    icon: resultPromissesPerfis[i].icon,
                                    order: resultPromissesPerfis[i].order || 0,
                                    ativo: resultPromissesPerfis[i].ativo,
                                    label: resultPromissesPerfis[i].label
                                })
                            }
                        })
                    })
                }

                // Mantem atualizada uma cópia do user profile para utilização do front
                return admin.database().ref('usuario').child(result.user.uid).set(result);
            })

            .then(_ => {
                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}


exports.requestUserProfile = (request, response) => {

    const uid = request.params.uid || request.query.uid || null;
    const token = global.getUserTokenFromRequest(request, response);

    if (!uid || !token) return response.status(500).json(global.defaultResult({ error: 'parm error' }));

    return getUserProfile(uid)
        .then(profile => {
            return response.status(200).json(
                global.defaultResult({ data: profile })
            );
        })
        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({ error: e.message })
            );
        })

}


const getUserInfo = uid => {
    return new Promise((resolve, reject) => {

        let userRecord;

        admin.auth().getUser(uid)

            .then(resultUserRecord => {
                userRecord = Object.assign({}, resultUserRecord);

                userRecord.customClaims = userRecord.customClaims || {};
                userRecord.customClaims.superUser = userRecord.customClaims.superUser || (uid === idSuperUser);
                userRecord.idConfigProfile = userRecord.customClaims.idConfigProfile || null;

                if (userRecord.customClaims.superUser) {
                    return getEmpresasSuperUser(userRecord.idConfigProfile || 'bIOIFnaGz7CYUsS1WA9P');
                } else {
                    return getEmpresasPerfilUsuarioNormal(userRecord);
                }

            })

            .then(list => {
                userRecord.empresas = list;

                let idEmpresaAtual = userRecord.customClaims.idEmpresa || null;

                if (!idEmpresaAtual && userRecord.customClaims.superUser && userRecord.empresas.length > 0) {
                    idEmpresaAtual = userRecord.empresas[0].id;
                }

                const i = userRecord.empresas.findIndex(f => { return f.id === idEmpresaAtual; });

                if (i >= 0) {
                    userRecord.empresas[i].selected = true;
                    userRecord.empresaAtual = userRecord.empresas[i];
                }

                userRecord.empresas = _.sortBy(userRecord.empresas, ['nome']);

                // Dados do profile (alguns dados não estão no token);
                return collectionUserProfile.getDoc(uid);
            })

            .then(userProfile => {
                // Dados adicionais (não se esqueça de atualizar formatUserObj)...
                if (userProfile.dtNascimento) userRecord.dtNascimento = userProfile.dtNascimento;

                return resolve(formatUserObj(userRecord));
            })

            .catch(e => {
                console.error(e);
                return reject(e);
            })
    })
}


const getEmpresasSuperUser = idPerfil => {
    return new Promise((resolve, reject) => {
        const result = [];

        admin
            .firestore()
            .collection('empresas')
            .where('ativo', '==', true)
            .get()

            .then(list => {

                list = fbHelper.toList(list);

                list.forEach(l => {
                    result.push(Object.assign(l,
                        {
                            id: l.id,
                            idPerfil: idPerfil
                        })
                    );
                })

                return resolve(result);
            })

            .catch(e => {
                console.error(e);
                throw e;
            })
    })
}


const getEmpresasPerfilUsuarioNormal = userRecord => {
    return new Promise((resolve, reject) => {

        const result = [],
            promisseEmpresas = [];

        admin
            .firestore()
            .collection('userProfile')
            .doc(userRecord.uid)
            .collection('empresas')
            .get()

            .then(list => {

                list = fbHelper.toList(list);

                list.forEach(l => {
                    result.push({ id: l.id, idPerfil: l.idPerfil });
                    promisseEmpresas.push(admin.firestore().collection('empresas').doc(l.id).get());
                })

                return Promise.all(promisseEmpresas);
            })

            .then(empresas => {

                empresas = fbHelper.toDocArray(empresas);

                empresas.forEach(e => {
                    if (e && e.ativo) {
                        const i = result.findIndex(f => { return f.id === e.id; });

                        if (i >= 0) {
                            result[i].nome = e.nome;
                            result[i].nomeExibicao = e.nomeExibicao;
                            result[i].representante_celular = e.representante_celular || null;
                            result[i].representante_celular_formatted = e.representante_celular_formatted || null;
                            result[i].representante_email = e.representante_email || null;
                        }
                    }
                })

                return resolve(result);
            })

            .catch(e => {
                console.error(e);
                throw e;
            })

    })
}


const formatUserObj = user => {

    const result = {
        uid: user.uid,
        email: user.email || null,
        emailVerified: user.emailVerified,
        displayName: user.displayName || null,
        photoURL: user.photoURL || null,
        phoneNumber: user.phoneNumber || null,
        disabled: user.disabled,
        dtNascimento: user.dtNascimento || null,
        lastSignInTime: (user.metadata && user.metadata.lastSignInTime ? moment(user.metadata.lastSignInTime).format("YYYY-MM-DD HH:MM:ss") : null),
        creationTime: (user.metadata && user.metadata.creationTime ? moment(user.metadata.creationTime).format("YYYY-MM-DD HH:MM:ss") : null),
        providerData: [],
        empresas: user.empresas || [],
        customClaims: user.customClaims
    };

    result.idEmpresa = (user.customClaims || {}).idEmpresa || null;

    if ((user.customClaims || {}).cpf) {
        result.cpf = user.customClaims.cpf;
    }

    if (user.empresaAtual) {
        result.empresaAtual = user.empresaAtual;
    }

    if ((user.customClaims || {}).superUser) {
        result.superUser = true;
    }

    (user.providerData || []).forEach(p => {
        result.providerData.push(p.providerId);
    });

    return result;

}


const setCpfOnCustomUserClaims = (uid, profileData) => {

    // O CPF só pode ser adicionado ao CustomClaim do usuário UMA VEZ!
    // A rotina já fez esta verificação...
    let userData;

    return new Promise((resolve, reject) => {

        admin.auth().getUser(uid)

            .then(result => {

                userData = result;

                const customClaims = userData.customClaims || {};

                // Se existir um CPF no CustomClaims mas não for o mesmo, retorna erro...
                if (customClaims.cpf && customClaims.cpf !== profileData.cpf) {
                    throw new Error('Não é possível modificar o CPF de uma conta...');
                }

                // Se não houver nenhum CPF no CustomClaims... seta.
                if (!customClaims.cpf) {
                    customClaims.cpf = profileData.cpf;
                    return admin.auth().setCustomUserClaims(uid, customClaims);
                } else {
                    return null;
                }

            })

            .then(_ => {

                // Atualiza outras informações do usuário
                const updateUser = {
                    displayName: profileData.displayName || userData.displayName || null
                }

                return admin.auth().updateUser(uid, updateUser);

            })

            .then(_ => {
                return resolve();
            })

            .catch(e => {
                return reject(e);
            })
    })
}


const setCustomUserClaims = (uid, customObj) => {

    return new Promise((resolve, reject) => {

        return admin.auth().setCustomUserClaims(uid, customObj)
            .then(() => {
                return resolve(true);
            })
            .catch(e => {
                return reject(e);
            })

    })

}


const updateUserData = (uid, data) => {
    return new Promise((resolve, reject) => {

        admin
            .auth()
            .updateUser(uid, data)
            .then(() => {
                return resolve(true)
            })
            .catch((error) => {
                return reject(new Error("Erro atualizando dados do usuário..."));
            });

    })
}


const getCurrentUserFromCookie = (request, response) => {
    return new Promise(resolve => {

        const Cookies = require("cookies");
        const cookies = new Cookies(request, response);
        const userToken = cookies.get("__session") || request.body.__session || null;
        const host = global.getHost(request);

        if (host === 'localhost' && userToken) {
            console.log('\x1b[36m%s\x1b[0m', 'userToken em Localhost:');
            console.log('\x1b[33m%s\x1b[0m', userToken);
        }

        if (!userToken) {
            return resolve(null);
        } else {

            return admin.auth().verifyIdToken(userToken)

                .then(user => {
                    return getUserInfo(user.uid);
                })

                .then(user => {

                    user.superAdm = (typeof user.superAdm === 'boolean' ? user.superAdm : false);
                    user.idEmpresa = user.idEmpresa || null;

                    return resolve(user);
                })

                .catch(e => {
                    return resolve(null);
                })
        }
    })
}


exports.updateUserProfile = (request, response) => {

    const token = global.getUserTokenFromRequest(request, response),
        displayName = request.body.displayName || null,
        email = request.body.email || null,
        dtNascimento = request.body.dtNascimento || null;

    let tokenData,
        userData,
        profileData,
        customClaims,
        phoneNumber,
        celular,
        cpf = request.body.cpf || null;

    if (!cpf || !token) {
        return response.status(500).json(global.defaultResult({ code: 500, error: 'CPF e Token devem ser preenchidos...' }));
    }

    if (email && !global.emailIsValid(email)) {
        return response.status(500).json(global.defaultResult({ code: 500, error: `Email invalido [${email}]` }));
    }

    if (dtNascimento && !global.isValidDtNascimento(dtNascimento)) {
        return response.status(500).json(global.defaultResult({ code: 500, error: 'Data de Nascimento inválida' }));
    }

    cpf = global.numbersOnly(cpf);

    if (!global.isCPFValido(cpf)) {
        return response.status(500).json(global.defaultResult({ code: 500, error: 'CPF Invalido' }));
    }

    // Carrega os dados do token.
    return getUserInfoWithToken(token)
        .then(result => {

            if (result.tokenSource !== 'firebase') throw new Error(`Not a Firebase Token: only Firebase tokens can update users...`);

            tokenData = result.data;

            // Os dados do token tem que ter phoneNumber
            if (!tokenData.phoneNumber) throw new Error(`Null phoneNumber on token`);

            phoneNumber = tokenData.phoneNumber;
            celular = phoneNumber.substr(3);

            // Carrega dos dados do usuário do Firebase
            return admin.auth().getUser(tokenData.uid);
        })

        .then(result => {

            userData = result;
            customClaims = userData.customClaims || {};

            if (userData.phoneNumber !== phoneNumber) {
                throw new Error(`Invalid phoneNumber for token [${userData.phoneNumber}]<>[${phoneNumber}] `);
            }

            if (customClaims && customClaims.cpf && customClaims.cpf !== cpf) {
                throw new Error(`O CPF não coincide com o da autenticação atual [${customClaims.cpf}]<>[${cpf}]`);
            }

            // Busca o profile do usuário no userProfile do Firestore
            return collectionUserProfile.getDoc(userData.uid, false);

        })

        .then(result => {

            profileData = result || {};

            if (profileData.cpf && profileData.cpf !== cpf) {
                throw new Error(`O CPF não coincide com o do profile do usuário [${profileData.cpf}]<>[${cpf}]`);
            }

            if (!profileData.cpf) { profileData.cpf = cpf; }
            if (!profileData.phoneNumber) { profileData.phoneNumber = phoneNumber; }

            if (userData.photoURL) {
                profileData.photoURL = userData.photoURL;
            }

            profileData.ativo = !userData.disabled;
            profileData.displayName = displayName || userData.displayName || null;
            profileData.emailVerified = userData.emailVerified;

            if (userData.email || email) {
                profileData.email = userData.email || email || null;
            }

            if (dtNascimento) {
                profileData.dtNascimento = dtNascimento;
                profileData.dtNascimento_timestamp = global.asTimestampData(dtNascimento, true);
            }

            profileData.dtInclusao = profileData.dtInclusao || global.now();
            profileData.dtAlteracao = global.now();

            profileData.keywords = global.generateKeywords(
                displayName || profileData.displayName,
                profileData.cpf,
                celular,
                email || profileData.email,
                userData.uid
            );

            delete profileData.id;
            delete profileData.uid;

            return collectionUserProfile.merge(userData.uid, profileData);

        })

        .then(_ => {

            return setCpfOnCustomUserClaims(userData.uid, profileData);

        })

        .then(_ => {

            return response.status(200).json(
                global.defaultResult({ data: { uid: userData.uid, phoneNumber: phoneNumber } }, true)
            );

        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({ error: e.message })
            );
        })


}


exports.requestFindUserProfileByCpfCelular = (request, response) => {

    const cpf = request.body.cpf || null,
        celular = request.body.celular || null,
        id = request.body.id || null,
        hash = request.body.hash || null,
        token = global.getUserTokenFromRequest(request, response);

    if (!cpf || !celular || !id || !token || !hash) {
        return response.status(500).json(global.defaultResult({
            code: 500,
            error: 'Requisição inválida'
        }));
    }

    return getUserInfoWithToken(token)

        .then(_ => {
            return findUserProfileByCpfCelular(cpf, celular, id, hash);
        })

        .then(result => {
            return response.status(200).json(
                global.defaultResult({
                    data: result
                }, true)
            );
        })

        .catch(e => {
            return response.status(e.code || 500).json(
                global.defaultResult({
                    error: e.message
                })
            );
        })

}


const getUserByPhoneNumber = number => {
    return new Promise(resolve => {
        return getAuth().getUserByPhoneNumber(number)
            .then(result => {
                return resolve(result);
            })
            .catch(e => {
                console.error(e);
                return resolve(null);
            })
    })
}


const getUserByUid = uid => {
    return new Promise(resolve => {
        return getAuth().getUser(uid)
            .then(result => {
                return resolve(result);
            })
            .catch(e => {
                console.error(e);
                return resolve(null);
            })
    })
}


const findUserProfileByCpfCelular = (cpf, celular, idSnapshot, hash) => {
    return new Promise((resolve, reject) => {

        cpf = global.numbersOnly(cpf);
        celular = global.numbersOnly(celular);

        // console.info(`findUserProfileByCpfCelular - cpf: ${cpf}, celular: ${celular}`);

        if (!cpf || !celular || !idSnapshot || !hash || cpf.length !== 11 || celular.length !== 11 || idSnapshot.length < 10 || hash < 10) {
            return reject(new Error('Invalid data'));
        }

        const path = `/_ic/${idSnapshot}`;
        const phoneNumber = '+55' + celular;

        let userData,
            profileDataCpf,
            profileDataPhoneNumber,
            cpfOnCustomClaim;

        const promisseProfileIds = [],
            result = {
                op: 'findUserProfileByCpfCelular',
                cpf: cpf,
                phoneNumber: phoneNumber,
                hash: hash,
                error: true
            };

        // Nova rotina. Quem manda não é o profile, mas sim o usuário do google
        return getUserByPhoneNumber(phoneNumber)

            .then(resultGetUserByPhoneNumber => {

                // console.info(`findUserProfileByCpfCelular: 1`, resultGetUserByPhoneNumber);

                userData = resultGetUserByPhoneNumber;

                // Procura os profiles que tem o mesmo CPF
                return collectionUserProfile.get({ filter: { cpf: cpf } });
            })

            .then(userProfileResult => {
                profileDataCpf = userProfileResult;

                // console.info(`findUserProfileByCpfCelular: 2`, userProfileResult);

                profileDataCpf.forEach(doc => {
                    if (!promisseProfileIds.includes(doc.id)) {
                        promisseProfileIds.push(doc.id);
                    }
                })

                // Procura os profiles que tem o mesmo phoneNumber
                return collectionUserProfile.get({ filter: { phoneNumber: phoneNumber } });

            })

            .then(userProfileResult => {

                profileDataPhoneNumber = userProfileResult;

                profileDataPhoneNumber.forEach(doc => {
                    if (!promisseProfileIds.includes(doc.id)) {
                        promisseProfileIds.push(doc.id);
                    }
                })

                // É possível que retorna mais do que um CPF em emProfiles.
                // Isso acontece porque o acesso do APP é feito via CPF e o do
                // ADM via eMail. Ambos são acessos diferentes que podem apontar para o mesmo CPF

                promisseProfileIds.forEach((id, i) => { promisseProfileIds[i] = admin.auth().getUser(id); })

                return Promise.all(promisseProfileIds);
            })

            .then(resultProfileIds => {

                // Deixa a consulta mais simples...
                const providers = [];

                resultProfileIds.forEach(r => {
                    if (r && r.providerData) {
                        r.providerData.forEach(p => {
                            providers.push({ uid: r.uid, providerId: p.providerId });
                        })
                    }
                })

                // Filtra os resultados do Profile. Apenas profile do tipo phone são utilizados.
                profileDataCpf = profileDataCpf.filter(profile => {
                    return providers.findIndex(provider => {
                        return profile.id === provider.uid && provider.providerId === 'phone';
                    }) >= 0;
                })

                profileDataPhoneNumber = profileDataPhoneNumber.filter(profile => {
                    return providers.findIndex(provider => {
                        return profile.id === provider.uid && provider.providerId === 'phone';
                    }) >= 0;
                })

                if (profileDataCpf.length >= 2) {
                    return result.msg = 'Cadastro bloqueado. Existe mais do que um perfil com o mesmo CPF. Entre em contato com nossa equipe de atendimento.'
                }
                else if (profileDataPhoneNumber.length >= 2) {
                    return result.msg = 'Cadastro bloqueado. Existe mais do que um perfil com o mesmo Celular   . Entre em contato com nossa equipe de atendimento.'
                }
                else {

                    profileDataCpf = profileDataCpf.length ? profileDataCpf[0] : null;
                    profileDataPhoneNumber = profileDataPhoneNumber.length ? profileDataPhoneNumber[0] : null;
                    cpfOnCustomClaim = userData && userData.customClaims && userData.customClaims.cpf ? userData.customClaims.cpf : null;

                    if (userData && cpfOnCustomClaim && cpfOnCustomClaim !== cpf) {
                        return result.msg = `O Celular já está vinculado ao CPF ${global.hideCpf(cpfOnCustomClaim)}.`;
                    }

                    if (profileDataCpf && profileDataCpf.phoneNumber !== phoneNumber) {
                        return result.msg = `O CPF já está vinculado ao número ${global.hideCelular(profileDataCpf.phoneNumber)}.`;
                    }

                    if (profileDataPhoneNumber && profileDataPhoneNumber.cpf !== cpf) {
                        return result.msg = `Erro no perfil do usuário. O CPF do perfil (${global.hideCpf(profileDataPhoneNumber.cpf)}) não coincide com o da autenticação existente. Entre em contato com nossa equipe de atendmento.`;
                    }

                }

                return result.error = false;

            })

            .then(_ => {
                return admin.database().ref(path).set(result);
            })

            .then(_ => {
                return resolve(result);
            })

            .catch(e => {
                return reject(e);
            })

    })
}


exports.getUserInfo = getUserInfo;
exports.getUserInfoWithToken = getUserInfoWithToken;
exports.getUserByUid = getUserByUid;
exports.findUserProfileByCpfCelular = findUserProfileByCpfCelular;
exports.getCurrentUserFromCookie = getCurrentUserFromCookie;
exports.getUserProfile = getUserProfile;

