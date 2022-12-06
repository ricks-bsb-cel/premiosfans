"use strict";

const path = require('path');
const global = require('../global');
const adminController = require('./adminController');
// const users = require('../api/users/users');

const updateUserProfile = require('../eeb/services/users/updateUserProfile');
const helper = require('../eeb/eventBusServiceHelper');

const hbsPath = path.join(__dirname, '/hbs');
const hbsFile = path.join(hbsPath, '/home.hbs');
const hbsPartials = path.join(hbsPath, '/partials/home');

const firestoreDAL = require('../api/firestoreDAL');
const collectionConfigPath = firestoreDAL.admConfigPath();

exports.get = (request, response) => {

    global.mapHandlebarDir(hbsPartials);

    helper.getUserTokenFromRequest(request, response)

    let result, promissesPerfis = [];

    return updateUserProfile.updateWithToken(request, response)

        .then(updateUserProfileResult => {
            return adminController.getPermissions(updateUserProfileResult);
        })

        .then(getPermissionsResult => {
            result = getPermissionsResult;

            if (!result.user || !result.user.userProfile || !result.user.userProfile.groups) return null;

            result.user.userProfile.groups.forEach(g => {
                g.options.forEach(o => {
                    promissesPerfis.push(collectionConfigPath.getDoc(o.id));
                })
            })

            return Promise.all(promissesPerfis);
        })

        .then(resultPromissesPerfis => {

            if (resultPromissesPerfis) {
                result.user.userProfile.groups.forEach(g => {
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

            if (result.redirect === '/adm/home') {
                return response.render(hbsFile, result);
            } else {
                return response.redirect(result.redirect);
            }
        })

        .catch(e => {
            console.error(e);
            return response.send(e);
        })

}
